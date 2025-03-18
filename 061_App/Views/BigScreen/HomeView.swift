import SwiftUI
import AVKit

struct HomeView: View {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
  @State private var showSplash = true
  @State private var showIntro = false
  @StateObject private var effectsViewModel = EffectsViewModel()
  @EnvironmentObject private var networkMonitor: NetworkMonitor

  var body: some View {
    ZStack {
      if showSplash {
        SplashScreen()
          .transition(.opacity)
      } else if !hasSeenOnboarding {
        OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
          .environmentObject(effectsViewModel)
      } else {
        CustomTabBarView()
      }
      
      VStack {
        NetworkAlertView()
          .animation(.easeInOut, value: networkMonitor.isConnected)
        Spacer()
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        withAnimation {
          showSplash = false
          if !hasSeenOnboarding {
            showIntro = true
          }
        }
      }
    }
  }
}

struct SplashScreen: View {
  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      Image("splash")
        .resizable()
        .frame(width: 100, height: 100)
        .cornerRadius(20)
    }
  }
}


struct MainAppView: View {
  var body: some View {
    Text("Main App Content")
      .font(.largeTitle)
  }
}
