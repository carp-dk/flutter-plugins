#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pedometer.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pedometer'
  s.version          = '4.2.0'
  s.summary          = 'Pedometer and Step Detection for Android and iOS'
  s.description      = <<-DESC
Pedometer and Step Detection for Android and iOS
                       DESC
  s.homepage         = 'https://github.com/carp-dk/flutter-plugins/tree/master/packages/pedometer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CARP Team' => 'support@carp.dk' }
  s.source           = { :path => '.' }
  s.source_files     = 'pedometer/Sources/pedometer/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
