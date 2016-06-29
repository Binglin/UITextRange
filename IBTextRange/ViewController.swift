//
//  ViewController.swift
//  UITextInputConstraits
//
//  Created by ET|冰琳 on 16/2/25.
//  Copyright © 2016年 Ice Butterfly. All rights reserved.
//

import UIKit

class ViewController: UIViewController{
    
    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var textView: UITextView!

    @IBOutlet weak var textViewRemainLabel: UILabel!
    @IBOutlet weak var textfieldRemainText: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.field.text = "123"
        self.textView.text = "1"
        
        self.textView.observerTextLengthChanged {[unowned self] (le) in
            print("lenght change")
            self.textViewRemainLabel.text = "(" + "\(self.textView.getRemainTextLength())" + ")"
            
        }
        self.field.observerTextLengthChanged {[unowned self] (len) in
            self.textfieldRemainText.text = "(" + "\(self.field.getRemainTextLength())" + ")"
        }
        
        self.textView.placeholder = "请输入"
        self.textView.maxLength = 30;
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

