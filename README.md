# UITextRange

* UITextField category that could limit text length
* UITextView  category that could limit text length
* UITextView placeholder property


###通过属性设置即可实现限制最大的输入长度
可在xib or storyboard中设置

##UITextField
``` 
let field: UITextField
field.maxLength = 10
```

###UITextView 所有属性均可在interface builder中设置 文本长度的变化可通过监听属性currentLength
```
textView: UITextView
textView.maxLength = 10
```
placeholder like UITextField

```
textView.placeholder = "在此输入内容"
```






## Install

```
pod 'IBTextRange', '~> 1.0.1'
```