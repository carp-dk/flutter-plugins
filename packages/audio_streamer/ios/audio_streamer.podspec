#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_streamer.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'audio_streamer'
  s.version          = '5.0.0'
  s.summary          = 'Streaming of PCM audio from Android and iOS'
  s.description      = <<-DESC
Streaming of PCM audio from Android and iOS
                       DESC
  s.license          = { :file => '../LICENSE' }
  s.homepage         = 'https://carp.dk'
  s.author           = { 'Copenhagen Research Platform' => 'support@carp.dk' }
  s.source           = { :path => '.' }
  s.source_files = 'audio_streamer/Sources/audio_streamer/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = { 'audio_streamer_privacy' => ['audio_streamer/Sources/audio_streamer/PrivacyInfo.xcprivacy'] }
end
