# Clix iOS SDK

Clix iOS SDK는 iOS 애플리케이션에서 푸시 알림을 관리하고 사용자 이벤트를
추적하는 데 사용되는 SDK입니다.

## 설치 방법

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-username/clix-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'Clix'
```

## 사용 방법

### 초기화

```swift
import Clix

// SDK 초기화
let config = ClixConfig(apiKey: "YOUR_API_KEY")
Task {
    try await Clix.shared.initialize(config: config)
}
```

### 사용자 ID 설정

```swift
// 사용자 ID 설정
Task {
    try await Clix.shared.setUserId("user123")
}

// 사용자 ID 제거
Task {
    try await Clix.shared.removeUserId()
}
```

### 사용자 속성 설정

```swift
// 사용자 속성 설정
Task {
    try await Clix.shared.setAttribute("name", value: "John Doe")
}
```

### 이벤트 추적

```swift
// 이벤트 추적
Task {
    try await Clix.shared.trackEvent("button_clicked", properties: ["button_id": "login_button"])
}
```

### 푸시 알림 처리

```swift
// AppDelegate에서 푸시 알림 처리
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task {
        try? await Clix.shared.handleDeviceToken(deviceToken)
    }
}

// 푸시 알림 수신 처리
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    Clix.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
}

// 푸시 알림 응답 처리
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    Clix.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
}
```

## 로깅

```swift
// 로깅 레벨 설정
Clix.setLogLevel(.debug)
```

## 리셋

```swift
// SDK 리셋
Clix.shared.reset()
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE)
파일을 참조하세요.
