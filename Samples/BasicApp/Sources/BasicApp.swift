import SwiftUI
import Clix

@main
struct BasicApp: App {
  @State private var isActive: Bool = false

  var body: some Scene {
    WindowGroup {
      ZStack {
        if isActive {
          ContentView()
        } else {
          SplashView()
        }
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          withAnimation {
            isActive = true
          }
        }
      }
    }
  }
}
