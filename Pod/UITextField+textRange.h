//
//  UITextField+textRange.h
//  UITextInputConstraits
//
//  Created by 冰琳 on 16/2/25.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^IBTextFieldLengthChangeBlock)(NSInteger currentLength);


@interface UITextField (textRange)

/**
 *  最大可输入字数
 */
@property (nonatomic, assign) IBInspectable NSInteger ib_maxLength;
@property (nonatomic, assign) IBInspectable NSInteger ib_minLength;

/**
 *  ⚠️ 本来设计为KVO监听currentLength 来修改应用剩余文本数量 但是当textView有默认text时，通过KVO，只能在监听后设置text 显示出来的文本长度才是正确的 or 在添加KVO前就设置好text了 则currentLength会不正确
 *  当前已输入文本的长度 中文未输入完成(料想的 有高亮的)的文本不计入已输入的长度
 *  表情符号eg 😄长度仅记为1 计算方式为NSStringEnumerationByComposedCharacterSequences
 */
@property (nonatomic, assign) NSInteger ib_currentLength;

/**
 *  剩余可输入文本的长度
 */
- (NSInteger)ib_getRemainTextLength;

/**
 *  文本长度是否在设置的范围内
 */
- (BOOL)ib_isTextValide;

/**
 *  监听文本长度变化
 *
 *  @param length 当前text length
 */
- (void)ib_observerTextLengthChanged:(IBTextFieldLengthChangeBlock)length;

@end
