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
        
        self.field.addObserver(self, forKeyPath: "currentLength", options: NSKeyValueObservingOptions.New, context: nil)
        
        self.textView.addObserver(self, forKeyPath: "currentLength", options: NSKeyValueObservingOptions.New, context: nil)

    }


    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "currentLength" {
            if object is UITextField{
                let _field = object as! UITextField
                self.textfieldRemainText.text = "(" + "\(_field.getRemainTextLength())" + ")"
            }else if object is UITextView{
                let _tView = object as! UITextView
                self.textViewRemainLabel.text = "(" + "\(_tView.getRemainTextLength())" + ")"
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

