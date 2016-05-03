//
//  UITextView+textRange.m
//  UITextInputConstraits
//
//  Created by 冰琳 on 16/2/25.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

#import "UITextView+textRange.h"
#import <objc/runtime.h>

static NSString * const _UITextViewDelegateKey = @"delegate";
static NSString * const _UITextViewTextKey     = @"text";

#pragma mark - UITextViewProxy
@interface UITextViewProxy : NSObject<UITextViewDelegate>

@property (nonatomic, assign) id<UITextViewDelegate> proxyDelegate;
@property (nonatomic, assign) UITextView * textView;

@end

@implementation UITextViewProxy

- (void)dealloc{
    [self.textView removeObserver:self forKeyPath:_UITextViewDelegateKey];
    [self.textView removeObserver:self forKeyPath:_UITextViewTextKey];
}

- (void)managerView:(UITextView *)view{
    
    self.textView = view;
    
    self.proxyDelegate = view.delegate;
    self.textView.delegate = self;
    
    [view addObserver:self forKeyPath:_UITextViewTextKey options:NSKeyValueObservingOptionNew context:nil];
    [view addObserver:self forKeyPath:_UITextViewDelegateKey options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView{
    if ([self.proxyDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.proxyDelegate textViewDidChange:textView];
    }
    [self computeLength];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    //range.length == 0表示删除文本
    if (textView.currentLength >= textView.maxLength && textView.markedTextRange == nil && range.length == 0){
        return NO;
    }
    
    if ([self.proxyDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [self.proxyDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:_UITextViewDelegateKey]) {
        if (object == self.textView) {
            if (self.textView.delegate != self) {
                self.proxyDelegate = [(UITextView *)object delegate];
                self.textView.delegate = self;
            }
        }
    }else if ([keyPath isEqualToString:_UITextViewTextKey]){
        [self computeLength];
    }
}

#pragma mark -
- (void)computeLength{
    
    NSString *_text ;
    
    //没有高亮的内容
    if (self.textView.markedTextRange == nil) {
        _text = self.textView.text;
    }
    // 有高亮的内容
    else{
        UITextRange *markedTextRange = self.textView.markedTextRange;
        UITextRange *inputedTextRange= [self.textView textRangeFromPosition:self.textView.beginningOfDocument toPosition:markedTextRange.start];
        _text = [self.textView textInRange:inputedTextRange];
    }
    
    __block NSInteger _textComposedLength = 0;
    __block NSInteger _textCharactorLength = 0;
    
    [_text enumerateSubstringsInRange:NSMakeRange(0, _text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        _textComposedLength += 1;
        if (_textComposedLength == self.textView.maxLength) {
            *stop = YES;
        }
        _textCharactorLength = substringRange.location + substringRange.length;
    }];
    
    self.textView.currentLength = _textComposedLength;
    
    if (_textCharactorLength < _text.length) {
        self.textView.text = [_text substringWithRange:NSMakeRange(0, _textCharactorLength)];
    }
    [self updatePlaceholder];
}

- (void)updatePlaceholder{
    self.textView.placeholderView.hidden = (self.textView.currentLength == 0) ? NO: YES;
}

@end


#pragma mark - UITextView (textRange)
@implementation UITextView (textRange)

/*
 * 可也用method swizzle
 * 不过发现在category中加入此方法也会被调用 
 * 说明UITextView中并没有实现此方法
 */
- (void)layoutSubviews{
    [super layoutSubviews];
    [self getPlaceholderView].frame = self.bounds;
}


#pragma mark - property
- (UITextViewProxy *)proxy{
    id _proxy = objc_getAssociatedObject(self, @selector(proxy));
    if (_proxy == nil) {
        _proxy = [UITextViewProxy new];
        [self setProxy:_proxy];
        [_proxy managerView:self];
    }
    return _proxy;
}

- (void)setProxy:(UITextViewProxy *)proxy{
    objc_setAssociatedObject(self, @selector(proxy), proxy, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -
- (NSInteger)maxLength{
    NSNumber *value = objc_getAssociatedObject(self, @selector(maxLength));
    return value ? value.integerValue : NSNotFound;
}

- (void)setMaxLength:(NSInteger)maxLength{
    objc_setAssociatedObject(self, @selector(maxLength), @(maxLength), OBJC_ASSOCIATION_RETAIN);
    [self proxy];
}

- (NSInteger)minLength{
    return [objc_getAssociatedObject(self, @selector(minLength)) integerValue];
}

- (void)setMinLength:(NSInteger)minLength{
    objc_setAssociatedObject(self, @selector(minLength), @(minLength), OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -
- (void)setCurrentLength:(NSInteger)currentLength{
    [self willChangeValueForKey:NSStringFromSelector(@selector(currentLength))];
    objc_setAssociatedObject(self, @selector(currentLength), @(currentLength), OBJC_ASSOCIATION_RETAIN);
    [self didChangeValueForKey:NSStringFromSelector(@selector(currentLength))];
}

- (NSInteger)currentLength{
    return [objc_getAssociatedObject(self, @selector(currentLength)) integerValue];
}

#pragma mark -
- (void)setPlaceholder:(NSString *)placeholder{
    self.placeholderView.text = placeholder;
}

- (NSString *)placeholder{
    return [self getPlaceholderView].text;
}

#pragma mark -
- (void)setPlaceholderView:(UITextView *)placeholderView{
    objc_setAssociatedObject(self, @selector(placeholderView), placeholderView, OBJC_ASSOCIATION_RETAIN);
}

- (UITextView *)placeholderView{
    UITextView *label = objc_getAssociatedObject(self, @selector(placeholderView));
    if (label == nil) {
        label = [UITextView new];
        label.font = self.font;
        label.textColor = [UIColor lightGrayColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.userInteractionEnabled = false;
        [self setPlaceholderView:label];
        [self addSubview:label];
    }
    return label;
}

- (UITextView *)getPlaceholderView{
    return objc_getAssociatedObject(self, @selector(placeholderView));
}

#pragma mark -
- (NSInteger)getRemainTextLength{
    return self.maxLength - self.currentLength;
}

- (BOOL)isTextValide{
    return self.currentLength >= self.minLength && self.currentLength <= self.maxLength;
}

@end
