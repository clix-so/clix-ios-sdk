# Clix iOS SDK

Clix iOS SDK는 iOS 애플리케이션에서 푸시 알림과 사용자 이벤트를 관리하기 위한 강력한 도구입니다. 사용자 참여와 분석을 위한 간단하고 직관적인 인터페이스를 제공합니다.

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/clix-so/clix-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'Clix'
```

## 요구사항

- iOS 13.0 이상
- Swift 5.5 이상

## 사용법

### 초기화

```swift
import Clix

// SDK 초기화
let config = ClixConfig(
    logLevel: .debug // 선택사항: 로깅 레벨 설정
)

Task {
    try await Clix.initialize(
        apiKey: "YOUR_API_KEY",
        endpoint: "https://api.clix.so", // 선택사항: 기본값은 https://api.clix.so
        config: config
    )
}
```

### 사용자 관리

```swift
// 사용자 ID 설정
Task {
    try await Clix.setUserId("user123")
}

// 사용자 ID 제거
Task {
    try await Clix.removeUserId()
}

// 사용자 속성 설정
Task {
    try await Clix.setAttribute("name", value: AnyCodable("John Doe"))
    try await Clix.setAttributes([
        "age": AnyCodable(25),
        "premium": AnyCodable(true)
    ])
}

// 사용자 속성 제거
Task {
    try await Clix.removeAttribute("name")
}
```

### 이벤트 추적

```swift
// 이벤트 추적
Task {
    try await Clix.trackEvent("button_clicked", properties: [
        "button_id": AnyCodable("login_button"),
        "screen": AnyCodable("login")
    ])
}
```

### 푸시 알림 통합

`AppDelegate`에서 `ClixAppDelegate`를 상속받아 사용하면 푸시 알림 관련 기능을 자동으로 처리할 수 있습니다:

```swift
import UIKit
import Clix

@main
class AppDelegate: ClixAppDelegate {
    // ClixAppDelegate가 이미 모든 필요한 메서드를 구현하고 있습니다
    // 필요한 경우 메서드를 오버라이드하여 커스터마이즈할 수 있습니다
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 상위 클래스의 구현을 호출하여 Clix 기능을 초기화
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // 여기에 추가적인 초기화 코드를 작성
        
        return result
    }
    
    // 알림 표시 방식을 커스터마이즈하려면 이 메서드를 오버라이드
    override func pushNotificationDeliveredInForeground(
        notification: UNNotification
    ) -> UNNotificationPresentationOptions {
        // 기본 구현은 iOS 14 이상에서 .list, .banner, .sound, .badge를 반환
        // iOS 13에서는 .alert, .sound, .badge를 반환
        return super.pushNotificationDeliveredInForeground(notification: notification)
    }
    
    // 알림 탭 처리를 커스터마이즈하려면 이 메서드를 오버라이드
    override func pushNotificationTapped(userInfo: [AnyHashable: Any]) {
        super.pushNotificationTapped(userInfo: userInfo)
        // 여기에 추가적인 처리 코드를 작성
    }
}
```

또는 직접 푸시 알림 관련 메서드를 구현할 수도 있습니다:

```swift
// 디바이스 토큰 등록 처리
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task {
        try? await Clix.shared.tokenService.setCurrentToken(deviceToken)
    }
}

// 등록 실패 처리
func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Clix.shared.logger.log(
        level: .error,
        category: .pushNotification,
        message: "Failed to register for remote notifications",
        error: error
    )
}

// 알림 수신 처리
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    Task {
        try? await Clix.shared.notificationService.handleNotificationReceived(
            notification.request.content.userInfo
        )
    }
    
    if #available(iOS 14.0, *) {
        completionHandler([.list, .banner, .sound, .badge])
    } else {
        completionHandler([.alert, .sound, .badge])
    }
}

// 알림 응답 처리
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    Task {
        try? await Clix.shared.notificationService.handleNotificationResponse(response)
        completionHandler()
    }
}
```

### 디바이스 토큰 관리

```swift
// 현재 디바이스 토큰 가져오기
let currentToken = Clix.shared.tokenService.getCurrentToken()

// 이전 디바이스 토큰 가져오기
let previousTokens = Clix.shared.tokenService.getPreviousTokens()
```

### 로깅

```swift
// 로깅 레벨 설정
Clix.setLogLevel(.debug)

// 사용 가능한 로깅 레벨:
// - .none: 로깅 비활성화
// - .error: 에러만 로깅
// - .warning: 경고와 에러 로깅
// - .info: 정보, 경고, 에러 로깅
// - .debug: 모든 로그 출력
```

### 초기화

```swift
// SDK 상태 초기화
Clix.reset()
```

## 주요 기능

- Swift Package Manager와 CocoaPods를 통한 쉬운 통합
- 포괄적인 푸시 알림 처리
- 사용자 식별 및 속성 관리
- 커스텀 속성을 포함한 이벤트 추적
- 디바이스 토큰 관리
- 구성 가능한 로깅 레벨
- 최신 Swift 개발을 위한 async/await 지원
- 알림 권한 자동 처리
- 미디어가 포함된 푸시 알림 지원
- 자동 재시도 및 오류 처리
- 백그라운드 알림 처리
- 디바이스 토큰 변경 자동 감지 및 처리

## 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
