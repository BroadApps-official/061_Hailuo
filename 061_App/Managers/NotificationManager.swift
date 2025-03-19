import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
  static let shared = NotificationManager()
  
  @Published var isNotificationsEnabled: Bool = false {
    didSet {
      print("📱 NotificationManager: Setting isNotificationsEnabled to \(isNotificationsEnabled)")
      UserDefaults.standard.set(isNotificationsEnabled, forKey: "isNotificationsEnabled")
      UserDefaults.standard.synchronize()
    }
  }
  private var isUpdatingStatus = false
  private var userManuallyDisabled = false
  
  private init() {
    print("📱 NotificationManager: Initializing")
    isNotificationsEnabled = UserDefaults.standard.bool(forKey: "isNotificationsEnabled")
    userManuallyDisabled = UserDefaults.standard.bool(forKey: "userManuallyDisabled")
    print("📱 NotificationManager: Loaded saved state: \(isNotificationsEnabled), manually disabled: \(userManuallyDisabled)")
    checkNotificationStatus()
    setupNotificationObservers()
  }
  
  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
  }
  
  @objc private func applicationWillEnterForeground() {
    print("📱 NotificationManager: App will enter foreground")
    checkNotificationStatus()
  }
  
  func checkNotificationStatus() {
    guard !isUpdatingStatus else { return }
    isUpdatingStatus = true
    
    print("📱 NotificationManager: Checking notification status")
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        let isAuthorized = settings.authorizationStatus == .authorized
        print("📱 NotificationManager: Status: \(settings.authorizationStatus.rawValue), isEnabled: \(isAuthorized)")
        
        if !self.userManuallyDisabled && isAuthorized != self.isNotificationsEnabled && settings.authorizationStatus != .denied {
          self.isNotificationsEnabled = isAuthorized
          UserDefaults.standard.synchronize()
        }
        self.isUpdatingStatus = false
      }
    }
  }
  
  func requestNotificationPermission() {
    guard !isUpdatingStatus else { return }
    isUpdatingStatus = true
    
    print("📱 NotificationManager: Requesting notification permission")
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        print("📱 NotificationManager: Permission granted: \(granted)")
        if granted {
          self.isNotificationsEnabled = true
          self.userManuallyDisabled = false
          UserDefaults.standard.set(false, forKey: "userManuallyDisabled")
          UserDefaults.standard.synchronize()
        }
        self.isUpdatingStatus = false
      }
    }
  }
  
  func disableNotifications() {
    guard !isUpdatingStatus else { return }
    isUpdatingStatus = true
    
    print("📱 NotificationManager: Disabling notifications")
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    DispatchQueue.main.async {
      self.isNotificationsEnabled = false
      self.userManuallyDisabled = true
      UserDefaults.standard.set(true, forKey: "userManuallyDisabled")
      UserDefaults.standard.synchronize()
      self.isUpdatingStatus = false
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
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

