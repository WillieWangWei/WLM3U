#
# Be sure to run `pod lib lint WLM3U.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WLM3U'
  s.version          = '0.1.0'
  s.summary          = 'A m3u video downloader.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A m3u video downloader using Swift.
                       DESC

  s.homepage         = 'https://github.com/WillieWangWei'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Willie' => 'willie.wangwei@gmail.com' }
  s.source           = { :git => 'https://github.com/WillieWangWei/WLM3U.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'WLM3U/Classes/**/*'
  
  # s.resource_bundles = {
  #   'WLM3U' => ['WLM3U/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Alamofire'
  s.swift_version = '5.0'
end
