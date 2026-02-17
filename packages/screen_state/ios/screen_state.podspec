#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint screen_state.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'screen_state'
  s.version          = '5.0.0'
  s.summary          = 'Base plugin for screen state detection.'
  s.description      = <<-DESC
https://github.com/cph-cachet/flutter-plugins/tree/master/packages/screen_state/ios.
                       DESC
  s.homepage         = 'https://github.com/cph-cachet/flutter-plugins/tree/master/packages/screen_state/ios'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tokenlab' => 'luansilva@tokenlab.com.br' }
  s.source           = { :path => '.' }
  s.source_files = 'screen_state/Sources/screen_state/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
