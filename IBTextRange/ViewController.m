//
//  ViewController.m
//  IBTextRange
//
//  Created by ET|冰琳 on 16/11/17.
//  Copyright © 2016年 IB. All rights reserved.
//

#import "ViewController.h"
#import "UITextView+textRange.h"
#import "UITextField+textRange.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UILabel *textFieldRemainTextLabel;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UILabel *textViewRemainTextLabel;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   [self.textView ib_observerTextLengthChanged:^(NSInteger currentLength) {
       self.textViewRemainTextLabel.text = [NSString stringWithFormat:@"UITextView字数限制 (%@)", @(10 - currentLength)];
   }];
    
    [self.textField ib_observerTextLengthChanged:^(NSInteger currentLength) {
        self.textViewRemainTextLabel.text = [NSString stringWithFormat:@"UITextView字数限制 (%@)", @(10 - currentLength)];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
