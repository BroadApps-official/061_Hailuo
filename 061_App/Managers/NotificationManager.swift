import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
  static let shared = NotificationManager()
  
  @Published var isNotificationsEnabled: Bool = false
  
  private init() {
    checkNotificationStatus()
  }
  
  func checkNotificationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        self.isNotificationsEnabled = settings.authorizationStatus == .authorized
      }
    }
  }
  
  func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        self.isNotificationsEnabled = granted
      }
    }
  }
  
  func disableNotifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    DispatchQueue.main.async {
      self.isNotificationsEnabled = false
    }
  }
  
  func sendVideoReadyNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Your video is ready! 🎉"
    content.body = "Check out your newly generated video in the Mine tab"
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request)
  }
}

