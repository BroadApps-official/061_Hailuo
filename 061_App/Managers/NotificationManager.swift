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
}

