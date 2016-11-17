//
//  UITextView+textRange.m
//  UITextInputConstraits
//
//  Created by 冰琳 on 16/2/25.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

#import "UITextView+textRange.h"
#import <objc/runtime.h>

static NSString * const _IBUITextViewDelegateKey = @"delegate";
static NSString * const _IBUITextViewTextKey     = @"text";

#pragma mark - UITextViewProxy
@interface UITextViewProxy : NSObject<UITextViewDelegate>

@property (nonatomic, assign) id<UITextViewDelegate> ib_proxyDelegate;
@property (nonatomic, assign) UITextView * ib_textView;
@property (nonatomic, copy  ) IBTextViewLengthChangeBlock ib_lengthChangeBlock;

@end

@implementation UITextViewProxy

- (void)dealloc{
    [self.ib_textView removeObserver:self forKeyPath:_IBUITextViewTextKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.ib_textView];
}

- (void)ib_managerView:(UITextView *)view{
    
    self.ib_textView = view;
    [self ib_computeLength];

    self.ib_proxyDelegate = view.delegate;
    self.ib_textView.delegate = self;
    
    [view addObserver:self forKeyPath:_IBUITextViewTextKey options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ib_proxy_textViewDidChange:) name:UITextViewTextDidChangeNotification object:view];
}

#pragma mark - UITextViewDelegate
- (void)ib_proxy_textViewDidChange:(UITextView *)textView{
    [self ib_computeLength];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    //range.length == 0,表示输入更多， range.length == 1则表示删除
    
    /* 如果仅输入到剩最后一个文字 用英文的九宫格快速切换 下面代码返回NO */
    if (textView.ib_currentLength > textView.ib_maxLength && textView.markedTextRange == nil && range.length == 0){
        return NO;
    }
    
    if ([self.ib_proxyDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [self.ib_proxyDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    
    return YES;
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:_IBUITextViewDelegateKey]) {
        if (object == self.ib_textView) {
            if (self.ib_textView.delegate != self) {
                self.ib_proxyDelegate = [(UITextView *)object delegate];
                self.ib_textView.delegate = self;
            }
        }
    }else if ([keyPath isEqualToString:_IBUITextViewTextKey]){
        [self ib_computeLength];
    }
}

#pragma mark -
- (void)ib_computeLength{
    
    NSString *_text ;
    
    //没有高亮的内容
    if (self.ib_textView.markedTextRange == nil) {
        _text = self.ib_textView.text;
    }
    // 有高亮的内容
    else{
        UITextRange *markedTextRange = self.ib_textView.markedTextRange;
        
        UITextRange *inputedStartTextRange= [self.ib_textView textRangeFromPosition:self.ib_textView.beginningOfDocument toPosition:markedTextRange.start];
        UITextRange *inputedEndTextRange = [self.ib_textView textRangeFromPosition:markedTextRange.end toPosition:self.ib_textView.endOfDocument];
        
        _text = [self.ib_textView textInRange:inputedStartTextRange];
        NSString *tail = [self.ib_textView textInRange:inputedEndTextRange];
        _text = [NSString stringWithFormat:@"%@%@",_text, tail.length ? tail : @""];
        NSLog(@"%@--%@",_text, tail);
    }
    
    __block NSInteger _textComposedLength = 0;
    __block NSInteger _textCharactorLength = 0;
    
    [_text enumerateSubstringsInRange:NSMakeRange(0, _text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        _textComposedLength += 1;
        if (_textComposedLength == self.ib_textView.ib_maxLength) {
            *stop = YES;
        }
        _textCharactorLength = substringRange.location + substringRange.length;
    }];
    
    self.ib_textView.ib_currentLength = _textComposedLength;
    
    if (_textCharactorLength < _text.length) {

        UITextRange *range = _ib_textView.selectedTextRange;
        self.ib_textView.text = [_text substringWithRange:NSMakeRange(0, _textCharactorLength)];
        self.ib_textView.selectedTextRange = range;
        
    }
    [self ib_updatePlaceholder];
}

- (void)ib_updatePlaceholder{
    self.ib_textView.ib_placeholderView.hidden = (self.ib_textView.ib_currentLength == 0 && (self.ib_textView.text.length == 0)) ? NO: YES;
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
    [self getIb_placeholderView].frame = self.bounds;
}

- (void)ib_observerTextLengthChanged:(IBTextViewLengthChangeBlock)length{
    [self ib_proxy].ib_lengthChangeBlock = length;
    
    //在添加KVO前就设置好text了 则currentLength会不正确 fix by:
    self.ib_currentLength = self.ib_currentLength;
}

- (void)_ib_updateRemainLength{
    if ([self ib_proxy].ib_lengthChangeBlock) {
        [self ib_proxy].ib_lengthChangeBlock(self.ib_currentLength);
    }
}

#pragma mark - property
- (UITextViewProxy *)ib_proxy{
    id _proxy = objc_getAssociatedObject(self, @selector(ib_proxy));
    if (_proxy == nil) {
        _proxy = [UITextViewProxy new];
        [self setIb_proxy:_proxy];
        [_proxy ib_managerView:self];
    }
    return _proxy;
}

- (void)setIb_proxy:(UITextViewProxy *)proxy{
    objc_setAssociatedObject(self, @selector(ib_proxy), proxy, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -
- (NSInteger)ib_maxLength{
    NSNumber *value = objc_getAssociatedObject(self, @selector(ib_maxLength));
    return value ? value.integerValue : NSNotFound;
}

- (void)setIb_maxLength:(NSInteger)ib_maxLength{
    objc_setAssociatedObject(self, @selector(ib_maxLength), @(ib_maxLength), OBJC_ASSOCIATION_RETAIN);
    [self ib_proxy];
    [self _ib_updateRemainLength];
}

- (NSInteger)ib_minLength{
    return [objc_getAssociatedObject(self, @selector(ib_minLength)) integerValue];
}

- (void)setIb_minLength:(NSInteger)ib_minLength{
    objc_setAssociatedObject(self, @selector(ib_minLength), @(ib_minLength), OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -
- (void)setIb_currentLength:(NSInteger)ib_currentLength{
    objc_setAssociatedObject(self, @selector(ib_currentLength), @(ib_currentLength), OBJC_ASSOCIATION_RETAIN);
    [self _ib_updateRemainLength];
}

- (NSInteger)ib_currentLength{
    return [objc_getAssociatedObject(self, @selector(ib_currentLength)) integerValue];
}

#pragma mark -
- (void)setIb_placeholder:(NSString *)placeholder{
    self.ib_placeholderView.text = placeholder;
    [self ib_proxy];
}

- (NSString *)ib_placeholder{
    return [self getIb_placeholderView].text;
}

#pragma mark -
- (void)setIb_placeholderView:(UITextView *)ib_placeholderView{
    objc_setAssociatedObject(self, @selector(ib_placeholderView), ib_placeholderView, OBJC_ASSOCIATION_RETAIN);
}

- (UITextView *)ib_placeholderView{
    UITextView *label = objc_getAssociatedObject(self, @selector(ib_placeholderView));
    if (label == nil) {
        label = [UITextView new];
        label.font = self.font;
        label.textColor = [UIColor lightGrayColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.userInteractionEnabled = false;
        [self setIb_placeholderView:label];
        [self addSubview:label];
    }
    return label;
}

- (UITextView *)getIb_placeholderView{
    return objc_getAssociatedObject(self, @selector(ib_placeholderView));
}

#pragma mark -
- (NSInteger)ib_getRemainTextLength{
    //[[self proxy] computeLength];
    return self.ib_maxLength - self.ib_currentLength;
}

- (BOOL)ib_isTextValide{
    return self.ib_currentLength >= self.ib_minLength && self.ib_currentLength <= self.ib_maxLength;
}

@end
