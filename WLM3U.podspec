Pod::Spec.new do |s|
  s.name                  = 'WLM3U'
  s.version               = '0.1.5'
  s.summary               = 'A m3u video downloader.'
  s.homepage              = 'https://github.com/WillieWangWei'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'Willie' => 'willie.wangwei@gmail.com' }
  s.source                = { :git => 'https://github.com/WillieWangWei/WLM3U.git', :tag => s.version.to_s }
  s.source_files          = 'Sources/*.swift'
  s.swift_version         = '5.1'
  s.ios.deployment_target = '10.0'
  s.dependency 'Alamofire'
end
