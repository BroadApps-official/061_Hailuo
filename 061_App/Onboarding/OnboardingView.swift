import SwiftUI
import StoreKit

struct OnboardingView: View {
  @Binding var hasSeenOnboarding: Bool
  @State private var currentPage = 0
  @State private var showAlert = false
  @StateObject private var viewModel = EffectsViewModel()
  
  let totalPages = 5
  
  var body: some View {
    VStack {
      GeometryReader { geometry in
        TabView(selection: $currentPage) {
          OnboardingPage(imageName: "onboardingImage1", title: "Inflate object in your photo", description: "", index: 0)
            .tag(0)
          OnboardingPage(imageName: "onboardingImage2", title: "Crumble any object", description: "", index: 1)
            .tag(1)
          OnboardingPage(imageName: "onboardingImage3", title: "Large variety of effects", description: "", index: 2)
            .tag(2)
          OnboardingPage(imageName: "onboardingImage4", title: "Rate our App in the Appstore", description: "", index: 3)
            .tag(3)
          OnboardingPage(imageName: "onboardingImage5", title: "Don't miss new trends", description: "Allow notifications", index: 4)
            .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.9)
      }
      
      HStack(spacing: 8) {
        ForEach(0..<totalPages) { i in
          Circle()
            .frame(width: 8, height: 8)
            .foregroundColor(currentPage == i ? .white : .gray)
        }
      }
      .padding(.top, -70)
      
      Button(action: {
        if currentPage == 3 {
          requestReview()
        } else if currentPage == 4 {
          showAlert = true
        } else {
          withAnimation {
            currentPage += 1
          }
        }
      }) {
        Text("Next")
          .font(Typography.bodyEmphasized)
          .frame(maxWidth: .infinity)
          .frame(height: 26)
          .padding()
          .background(GradientStyle.background)
          .foregroundColor(.black)
          .cornerRadius(8)
          .padding(.horizontal, 20)
      }
      .padding(.bottom, 30)
      .padding(.top, -50)
      
      
    }
    .background(.black)
    .edgesIgnoringSafeArea(.all)
    .onAppear {
      Task {
        await viewModel.fetchEffects()
      }
    }
    .alert("Enable Notifications?", isPresented: $showAlert) {
      Button("Allow") {
        requestNotificationPermission()
      }
      Button("Not now", role: .cancel) {
        hasSeenOnboarding = true
      }
    } message: {
      Text("Stay up to date with new AI features and tips by enabling notifications.")
    }
  }
  
  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      DispatchQueue.main.async {
        NotificationManager.shared.isNotificationsEnabled = granted
        hasSeenOnboarding = true
      }
    }
  }
  
  private func requestReview() {
    if let windowScene = UIApplication.shared.connectedScenes
      .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: windowScene)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      withAnimation {
        currentPage += 1
      }
    }
  }
}

#Preview {
  OnboardingView(hasSeenOnboarding: .constant(false))
}

