import SwiftUI

struct NotificationPermissionView: View {
  @Binding var hasSeenOnboarding: Bool
  @State private var showPermissionAlert = false
  @ObservedObject private var notificationManager = NotificationManager.shared
  
  var body: some View {
    VStack(spacing: 8) {
      Image("onboard5")
        .resizable()
        .scaledToFill()
        .frame(height: UIScreen.main.bounds.height * 0.6)
        .clipped()
      
      VStack {
        Text("Don't miss new \n trends")
          .font(Typography.bodyEmphasized)
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
        
        Text("Allow notifications")
          .font(Typography.bodyEmphasized)
          .foregroundColor(.white)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 20)
      
      Spacer()
      
      Button(action: {
        notificationManager.requestNotificationPermission()
        hasSeenOnboarding = true
      }) {
        Text("Turn on notifications")
          .font(Typography.bodyEmphasized)
          .frame(maxWidth: .infinity)
          .padding()
          .background(.white)
          .foregroundColor(.white)
          .cornerRadius(10)
          .padding(.horizontal, 20)
      }
      .padding(.bottom, 12)
      
      Button(action: {
        hasSeenOnboarding = true
      }) {
        Text("Maybe later")
          .font(Typography.bodyEmphasized)
          .foregroundColor(.white)
      }
      .padding(.bottom, 30)
    }
    .background(.black)
    .edgesIgnoringSafeArea(.all)
  }
  
  private func requestNotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      DispatchQueue.main.async {
        hasSeenOnboarding = true
      }
    }
  }
}

#Preview {
  NotificationPermissionView(hasSeenOnboarding: .constant(true))
}
