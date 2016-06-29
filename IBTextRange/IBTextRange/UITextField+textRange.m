//
//  UITextField+textRange.m
//  UITextInputConstraits
//
//  Created by 冰琳 on 16/2/25.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

#import "UITextField+textRange.h"
#import <objc/runtime.h>

static NSString * const _UITextFieldDelegateKey = @"delegate";
static NSString * const _UITextFieldTextKey     = @"text";

#pragma mark - UITextFieldProxy
@interface UITextFieldProxy : NSObject<UITextFieldDelegate>

@property (nonatomic, assign) id<UITextFieldDelegate> proxyDelegate;
@property (nonatomic, assign) UITextField * field;
@property (nonatomic, copy  ) TextFieldLengthChangeBlock lengthChangeBlock;


@end


@implementation UITextFieldProxy

- (void)dealloc{
    [self.field removeObserver:self forKeyPath:_UITextFieldDelegateKey];
    [self.field removeObserver:self forKeyPath:_UITextFieldTextKey];
}

- (void)managerView:(UITextField *)txtField{
    
    self.field = txtField;
    self.proxyDelegate = txtField.delegate;
    self.field.delegate = self;
    
    [txtField addObserver:self forKeyPath:_UITextFieldTextKey options:NSKeyValueObservingOptionNew context:nil];
    [txtField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [txtField addObserver:self forKeyPath:_UITextFieldDelegateKey options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - action
- (void)textFieldDidChange:(UITextField *)field{
    [self computeLength];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (range.length == 1) {
        return YES;
    }
    
    //range.length == 0,表示输入更多， range.length == 1则表示删除
    /* 如果仅输入到剩最后一个文字 用英文的九宫格快速切换 下面代码返回NO*/
    if (textField.currentLength >= textField.maxLength && textField.markedTextRange == nil && range.length == 0){
        return NO;
    }
    
    if ([self.proxyDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.proxyDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    
    return YES;
}


#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:_UITextFieldDelegateKey]) {
        if (object == self.field) {
            if (self.field.delegate != self) {
                self.proxyDelegate = [(UITextField *)object delegate];
                self.field.delegate = self;
            }
        }
    }else if ([keyPath isEqualToString:_UITextFieldTextKey]){
        [self computeLength];
    }
}

#pragma mark -
- (void)computeLength{
    
    NSLog(@"change: %@", self.field.text);
    
    NSString *_text ;
    
    //没有高亮的内容
    if (self.field.markedTextRange == nil) {
        _text = self.field.text;
    }
    // 有高亮的内容
    else{
        UITextRange *markedTextRange = self.field.markedTextRange;
        
        UITextRange *inputedStartTextRange= [self.field textRangeFromPosition:self.field.beginningOfDocument toPosition:markedTextRange.start];
        UITextRange *inputedEndTextRange = [self.field textRangeFromPosition:markedTextRange.end toPosition:self.field.endOfDocument];
        
        _text = [self.field textInRange:inputedStartTextRange];
        NSString *tail = [self.field textInRange:inputedEndTextRange];
        
        _text = [NSString stringWithFormat:@"%@%@",_text, tail.length ? tail : @""];
    }
    
    __block NSInteger _textComposedLength = 0;
    __block NSInteger _textCharactorLength = 0;
    
    [_text enumerateSubstringsInRange:NSMakeRange(0, _text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        _textComposedLength += 1;
        if (_textComposedLength == self.field.maxLength) {
            *stop = YES;
        }
        _textCharactorLength = substringRange.location + substringRange.length;
    }];
    
    self.field.currentLength = _textComposedLength;
    
    if (_textCharactorLength < _text.length) {
        
        UITextRange *range = _field.selectedTextRange;
        self.field.text = [_text substringWithRange:NSMakeRange(0, _textCharactorLength)];
        self.field.selectedTextRange = range;
    }
}

@end

#pragma mark - UITextField (max_text_length)
@implementation UITextField (max_text_length)

- (void)observerTextLengthChanged:(TextFieldLengthChangeBlock)length{
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
- (UITextFieldProxy *)proxy{
    id _proxy = objc_getAssociatedObject(self, @selector(proxy));
    if (_proxy == nil) {
        _proxy = [UITextFieldProxy new];
        [self setProxy:_proxy];
        [_proxy managerView:self];
    }
    return _proxy;
}

- (void)setProxy:(UITextFieldProxy *)proxy{
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

- (NSInteger)getRemainTextLength{
    return self.maxLength - self.currentLength;
}

- (BOOL)isTextValide{
    return self.currentLength >= self.minLength && self.currentLength <= self.maxLength;
}



@end
