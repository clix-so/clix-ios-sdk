Pod::Spec.new do |spec|
  spec.name             = 'Clix'
  spec.version          = '1.0.0'
  spec.summary          = 'Clix iOS SDK for push notifications and analytics'
  spec.description      = <<-DESC
Clix iOS SDK provides push notification and analytics capabilities for iOS apps.
                       DESC
  spec.homepage         = 'https://clix.so'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author           = { 'Clix' => 'support@clix.so' }
  spec.source           = { :git => 'https://github.com/clix-so/clix-ios-sdk.git', :tag => spec.version.to_s }
  spec.ios.deployment_target = '13.0'
  spec.swift_version = '5.5'
  spec.source_files = 'Sources/**/*'
  spec.frameworks = 'UIKit', 'UserNotifications'
  spec.dependency 'FirebaseCore', '>= 10.0.0'
  spec.dependency 'FirebaseMessaging', '>= 10.0.0'
end 
