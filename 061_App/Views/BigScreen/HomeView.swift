import SwiftUI
import AVKit

struct HomeView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasSeenPaywall") private var hasSeenPaywall = false
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @StateObject private var effectsViewModel = EffectsViewModel()
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else if showOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .environmentObject(effectsViewModel)
            } else if showPaywall {
                PaywallView()
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
                        showOnboarding = true
                    } else if !hasSeenPaywall {
                        showPaywall = true
                    }
                }
            }
        }
        .onChange(of: hasSeenOnboarding) { newValue in
            if newValue {
                withAnimation {
                    showOnboarding = false
                    if !hasSeenPaywall {
                        showPaywall = true
                    }
                }
            }
        }
        .onChange(of: hasSeenPaywall) { newValue in
            if newValue {
                withAnimation {
                    showPaywall = false
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
