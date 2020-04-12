#
#  Be sure to run `pod spec lint PDFEditor.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name = "PDFEditor"
  spec.version = "0.0.1"
  spec.summary = "Lightweight library that allow add annotations to pdf files with simple PDFEditView: UIView."
  spec.homepage = "https://github.com/cmuphobk/PdfEditor"
  spec.license = { :type => "MIT", :file => "https://github.com/cmuphobk/PdfEditor/blob/master/LICENSE" }
  spec.author = { "Kirill Smirnov" => "cmuphob.k@gmail.com" }
  # spec.social_media_url   = "https://twitter.com/ksmirnov
  spec.platform = :ios, "11.0"
  spec.swift_version = "5.0"
  spec.source = { :git => "git@github.com:cmuphobk/PdfEditor.git", :tag => "#{spec.version}" }
  spec.source_files = "PDFEditor/PDFEditor.h", "PDFEditor/Source/**/*.{swift}"

end
