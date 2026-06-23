#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint screen_state.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'screen_state'
  s.version          = '5.0.1'
  s.summary          = 'Plugin for screen state detection.'
  s.description      = <<-DESC
Plugin for screen state detection.
                       DESC
  s.homepage         = 'https://carp.dk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Copenhagen Research Platform' => 'support@carp.dk' }
  s.source           = { :path => '.' }
  s.source_files = 'screen_state/Sources/screen_state/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'screen_state_privacy' => ['screen_state/Sources/screen_state/PrivacyInfo.xcprivacy']}
end
