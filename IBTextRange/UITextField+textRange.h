//
//  UITextField+textRange.h
//  UITextInputConstraits
//
//  Created by 冰琳 on 16/2/25.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (textRange)

/**
 *  最大可输入字数
 */
@property (nonatomic, assign) IBInspectable NSInteger maxLength;
@property (nonatomic, assign) IBInspectable NSInteger minLength;

/**
 *  当前已输入文本的长度 中文未输入完成(料想的 有高亮的)的文本不计入已输入的长度
 *  表情符号eg 😄长度仅记为1 计算方式为NSStringEnumerationByComposedCharacterSequences
 */
@property (nonatomic, assign) NSInteger currentLength;

/**
 *  剩余可输入文本的长度
 */
- (NSInteger)getRemainTextLength;

/**
 *  文本长度是否在设置的范围内
 */
- (BOOL)isTextValide;

@end
