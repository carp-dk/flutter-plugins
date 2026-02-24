#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint light.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'light'
  s.version          = '4.1.1'
  s.summary          = 'A Flutter plugin for ambient light sensor data.'
  s.description      = <<-DESC
A Flutter plugin for collecting ambient light sensor data.
                       DESC
  s.homepage         = 'https://github.com/carp-dk/flutter-plugins/tree/master/packages/light'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CARP Team' => 'support@carp.dk' }
  s.source           = { :path => '.' }
  s.source_files     = 'light/Sources/light/**/*'
  s.dependency 'Flutter'
  s.weak_frameworks  = 'SensorKit'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
