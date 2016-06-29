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
@property (nonatomic, copy  ) TextViewLengthChangeBlock lengthChangeBlock;

@end

@implementation UITextViewProxy

- (void)dealloc{
    [self.textView removeObserver:self forKeyPath:_UITextViewTextKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.textView];
}

- (void)managerView:(UITextView *)view{
    
    self.textView = view;
    [self computeLength];

    self.proxyDelegate = view.delegate;
    self.textView.delegate = self;
    
    [view addObserver:self forKeyPath:_UITextViewTextKey options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proxy_textViewDidChange:) name:UITextViewTextDidChangeNotification object:view];
}

#pragma mark - UITextViewDelegate
- (void)proxy_textViewDidChange:(UITextView *)textView{
    [self computeLength];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    //range.length == 0,表示输入更多， range.length == 1则表示删除
    
    /* 如果仅输入到剩最后一个文字 用英文的九宫格快速切换 下面代码返回NO */
    if (textView.currentLength > textView.maxLength && textView.markedTextRange == nil && range.length == 0){
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
        
        UITextRange *inputedStartTextRange= [self.textView textRangeFromPosition:self.textView.beginningOfDocument toPosition:markedTextRange.start];
        UITextRange *inputedEndTextRange = [self.textView textRangeFromPosition:markedTextRange.end toPosition:self.textView.endOfDocument];
        
        _text = [self.textView textInRange:inputedStartTextRange];
        NSString *tail = [self.textView textInRange:inputedEndTextRange];
        _text = [NSString stringWithFormat:@"%@%@",_text, tail.length ? tail : @""];
        NSLog(@"%@--%@",_text, tail);
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

        UITextRange *range = _textView.selectedTextRange;
        self.textView.text = [_text substringWithRange:NSMakeRange(0, _textCharactorLength)];
        self.textView.selectedTextRange = range;
        
    }
    [self updatePlaceholder];
}

- (void)updatePlaceholder{
    self.textView.placeholderView.hidden = (self.textView.currentLength == 0 && (self.textView.text.length == 0)) ? NO: YES;
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

- (void)observerTextLengthChanged:(TextViewLengthChangeBlock)length{
    [self proxy].lengthChangeBlock = length;
    
    //在添加KVO前就设置好text了 则currentLength会不正确 fix by:
    self.currentLength = self.currentLength;
}

- (void)_updateRemainLength{
    if ([self proxy].lengthChangeBlock) {
        [self proxy].lengthChangeBlock(self.currentLength);
    }
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
    [self _updateRemainLength];
}

- (NSInteger)minLength{
    return [objc_getAssociatedObject(self, @selector(minLength)) integerValue];
}

- (void)setMinLength:(NSInteger)minLength{
    objc_setAssociatedObject(self, @selector(minLength), @(minLength), OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -
- (void)setCurrentLength:(NSInteger)currentLength{
    objc_setAssociatedObject(self, @selector(currentLength), @(currentLength), OBJC_ASSOCIATION_RETAIN);
    [self _updateRemainLength];
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
    //[[self proxy] computeLength];
    return self.maxLength - self.currentLength;
}

- (BOOL)isTextValide{
    return self.currentLength >= self.minLength && self.currentLength <= self.maxLength;
}

@end
