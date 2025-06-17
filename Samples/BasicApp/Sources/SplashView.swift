import SwiftUI

struct SplashView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      Image("Logo")
        .resizable()
        .scaledToFit()
        .frame(width: 180, height: 180)
    }
  }
}
