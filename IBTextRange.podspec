Pod::Spec.new do |s|

  s.name         = "IBTextRange"
  s.version      = "1.0.2"
  s.summary      = "UITextView and UITextField category of a property of maxLength . UITextView has a property called placeholder"
  s.homepage     = "https://github.com/Binglin/UITextRange"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author             = { "冰琳" => "269042025@qq.com" }
  s.ios.deployment_target = '6.0'
  s.source       = { :git => "https://github.com/Binglin/UITextRange.git", :tag => s.version }
  s.source_files  = "Pod"
  s.requires_arc = true

end
