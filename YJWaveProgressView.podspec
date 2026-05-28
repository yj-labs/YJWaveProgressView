Pod::Spec.new do |s|
  s.name         = "YJWaveProgressView"
  s.version      = "2.0.0"
  s.summary      = "一款圆形水波进度控件."
  s.description  = <<-DESC
	一款圆形水波进度控件，高度支持可定制开发，支持自动布局
                   DESC
  s.homepage     = "https://github.com/YongTaiSin/YJWaveProgressView"
  s.license      = "MIT"
  s.author       = { "Jeremiah" => "971175049@qq.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/YongTaiSin/YJWaveProgressView.git", :tag => s.version.to_s }
  s.source_files = "YJWaveProgressView/**/*.swift"
  s.swift_versions = ["5.0"]
  s.requires_arc = true

end
