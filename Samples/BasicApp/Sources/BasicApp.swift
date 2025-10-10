import SwiftUI
import UIKit

@main
struct BasicApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  init() {
    UITextView.appearance().backgroundColor = .clear
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
