Pod::Spec.new do |spec|
  spec.name             = 'Clix'
  # Don't modify below line - it's automatically updated by scripts/update-version.sh
  spec.version          = '1.4.1' # Don't modify this line - it's automatically updated by scripts/update-version.sh
  spec.summary          = 'Clix iOS SDK for push notifications and analytics'
  spec.description      = <<-DESC
Clix iOS SDK provides push notification and analytics capabilities for iOS apps.
                       DESC
  spec.homepage         = 'https://github.com/clix-so/clix-ios-sdk'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.author           = { 'Clix' => 'support@clix.so' }
  spec.source           = { :git => 'https://github.com/clix-so/clix-ios-sdk.git', :tag => spec.version.to_s }
  spec.ios.deployment_target = '15.0'
  spec.swift_version = '5.5'
  spec.source_files = 'Sources/**/*'
  spec.frameworks = 'UIKit', 'UserNotifications'
  spec.dependency 'FirebaseCore', '>= 10.0.0', '< 20.0.0'
  spec.dependency 'FirebaseMessaging', '>= 10.0.0', '< 20.0.0'
end
