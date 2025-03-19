import SwiftUI
import ApphudSDK
import StoreKit
import UserNotifications

struct SettingsView: View {
  @State private var isNotificationsEnabled = false
  @ObservedObject private var notificationManager = NotificationManager.shared
  @State private var isScrolled = false
  @State private var cacheSize: String = "Calculating..."
  @State private var isClearingCache = false
  @State private var showClearCacheAlert = false
  @State private var showPaywall = false
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Settings")
              .font(Typography.title1Emphasized)
              .foregroundColor(.white)
              .opacity(isScrolled ? 0 : 1)
            Spacer()
            ProBadgeButton()
              .scaleEffect(isScrolled ? 0.7 : 1.0)
          }
          .padding(.bottom, 16)
          
          SectionHeader(title: "Support us")
          SettingButton(title: "Rate app", icon: "set1", action: rateApp)
          SettingButton(title: "Share with friends", icon: "set2", action: shareApp)
          SectionHeader(title: "Purchases & Actions")
          SettingButton(title: "Upgrade plan", icon: "set3", action: upgradePlan)
          ToggleSetting(title: "Notifications", icon: "set4", isOn: $isNotificationsEnabled, action: toggleNotifications)
          SettingButton(title: "Clear cache", icon: "set5", extraText: cacheSize, action: { showClearCacheAlert = true })
          SettingButton(title: "Restore purchases", icon: "set6", action: restorePurchases)
          SectionHeader(title: "Info & legal")
          SettingButton(title: "Contact us", icon: "set7", action: contactSupport)
          SettingButton(title: "Privacy Policy", icon: "set8", action: openPrivacyPolicy)
          SettingButton(title: "Usage Policy", icon: "set9", action: openUsagePolicy)

          let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0"
          Text("App Version: \(version)")
            .foregroundColor(.gray)
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
        }
        .padding(.horizontal, 16)
        .background(GeometryReader { geo -> Color in
          DispatchQueue.main.async {
            isScrolled = geo.frame(in: .global).minY < -1
          }
          return Color.clear
        })
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("Settings")
            .font(.headline)
            .foregroundColor(.white)
            .opacity(isScrolled ? 1 : 0)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          ProBadgeButton(isCompact: true)
            .scaleEffect(isScrolled ? 1.0 : 0)
        }
      }
      .background(Color.black.edgesIgnoringSafeArea(.all))
      .toolbarBackground(.black, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .onAppear {
        isNotificationsEnabled = notificationManager.isNotificationsEnabled
        checkNotificationStatus()
        calculateCacheSize()
      }
      .onChange(of: notificationManager.isNotificationsEnabled) { newValue in
        print("📱 SettingsView: Notification status changed to \(newValue)")
        isNotificationsEnabled = newValue
      }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        checkNotificationStatus()
      }
      .fullScreenCover(isPresented: $showPaywall) {
        PaywallView()
      }
      .alert("Clear Cache", isPresented: $showClearCacheAlert) {
        Button("Cancel", role: .cancel) { }
        Button("Clear", role: .destructive) {
          clearCache()
        }
      } message: {
        Text("This will delete all temporary files and user-generated videos. Preview effects will not be affected.")
      }
    }
  }
  
  private func rateApp() {
    if #available(iOS 14, *) {
      if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
        DispatchQueue.main.async {
          AppStore.requestReview(in: scene)
        }
      }
    } else {
      let appID = "ID"
      if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(6743318475)?action=write-review") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }
  
  private func shareApp() {
    let appURL = "https://apps.apple.com/app/id6743318475"
    let shareText = "Check out this app!\n\(appURL)"
    let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
  }
  
  private func upgradePlan() {
    showPaywall = true
  }
  
  private func restorePurchases() {
    Task {
      do {
        let result = try await Apphud.restorePurchases()
        await MainActor.run {
          showAlert(title: "Success", message: "Your purchases have been restored")
        }
      } catch {
        await MainActor.run {
          showAlert(title: "Error", message: "Purchases could not be restored. Please try again later")
        }
      }
    }
  }

  private func ToggleSetting(title: String, icon: String, isOn: Binding<Bool>, action: @escaping () -> Void) -> AnyView {
    let toggle = Toggle("", isOn: isOn)
      .labelsHidden()
      .tint(ColorPalette.Accent.primary)
    
    let toggleWithAction = toggle.onChange(of: isOn.wrappedValue) { newValue in
      print("📱 SettingsView: Toggle changed to \(newValue)")
      if newValue {
        notificationManager.requestNotificationPermission()
      } else {
        notificationManager.disableNotifications()
      }
      UserDefaults.standard.synchronize()
    }
    
    return AnyView(
      HStack {
        Image(icon)
        Text(title)
          .foregroundColor(.white)
        Spacer()
        toggleWithAction
      }
      .padding()
      .background(ColorPalette.Background.primaryAlpha)
      .cornerRadius(12)
    )
  }

  private func checkNotificationStatus() {
    print("📱 SettingsView: Checking notification status")
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        let isAuthorized = settings.authorizationStatus == .authorized
        print("📱 SettingsView: System notification status: \(settings.authorizationStatus.rawValue), isEnabled: \(isAuthorized)")
        
        // Не обновляем состояние, если пользователь вручную отключил уведомления
        if !UserDefaults.standard.bool(forKey: "userManuallyDisabled") && isAuthorized != isNotificationsEnabled && settings.authorizationStatus != .denied {
          isNotificationsEnabled = isAuthorized
          notificationManager.isNotificationsEnabled = isAuthorized
          UserDefaults.standard.synchronize()
        }
      }
    }
  }

  private func toggleNotifications() {
    print("📱 SettingsView: Toggle notifications called")
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      DispatchQueue.main.async {
        switch settings.authorizationStatus {
        case .authorized:
          print("📱 SettingsView: Disabling notifications")
          notificationManager.disableNotifications()
          isNotificationsEnabled = false
          UserDefaults.standard.set(true, forKey: "userManuallyDisabled")
          UserDefaults.standard.synchronize()
        case .denied:
          print("📱 SettingsView: Notifications disabled in system settings")
          isNotificationsEnabled = false
          notificationManager.isNotificationsEnabled = false
          UserDefaults.standard.set(true, forKey: "userManuallyDisabled")
          UserDefaults.standard.synchronize()
        case .notDetermined:
          print("📱 SettingsView: Requesting notification permission")
          notificationManager.requestNotificationPermission()
        default:
          print("📱 SettingsView: Unknown notification status")
          break
        }
      }
    }
  }
  
  private func contactSupport() {
    let email = "trangvb086796@gmail.com"
    let subject = "Support Request"
    let body = "Hello, I need help with..."
    let emailURL = "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: emailURL) {
      UIApplication.shared.open(url)
    }
  }
  
  private func openPrivacyPolicy() {
    if let url = URL(string: "https://docs.google.com/document/d/11XBfYAuGvIj-tq7o22zMtqbmjH_Wp_ZZKU2ODwqwvDE/edit?usp=sharing") {
      UIApplication.shared.open(url)
    }
  }
  
  private func openUsagePolicy() {
    if let url = URL(string: "https://docs.google.com/document/d/1_aqT5H9GYmH1IDlyeTLvP0AUuOzHEhRiikDaaLY_G9A/edit?usp=sharing") {
      UIApplication.shared.open(url)
    }
  }
  
  private func clearCache() {
    isClearingCache = true
    Task {
      do {
        GeneratedVideosManager.shared.clearVideos()
        GeneratedVideosManager.shared.favoriteVideos.removeAll()
        VideoCacheService.shared.clearCache()
        
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let tempFiles = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        let documentFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        
        let videoExtensions = ["mp4", "mov", "m4v"]
        let filesToDelete = (tempFiles + documentFiles).filter { url in
          let isVideo = videoExtensions.contains(url.pathExtension.lowercased())
          let isTempFile = url.lastPathComponent.hasPrefix("temp_") || url.lastPathComponent.hasSuffix(".tmp")
          return isVideo || isTempFile
        }
        
        for fileURL in filesToDelete {
          do {
            try fileManager.removeItem(at: fileURL)
            print("✅ [SETTINGS] Delete file \(fileURL.lastPathComponent)")
          } catch {
            print("❌ [SETTINGS] Error deleting \(fileURL.lastPathComponent): \(error)")
          }
        }
        
        await MainActor.run {
          cacheSize = "0 MB"
          isClearingCache = false
        }
      } catch {
        await MainActor.run {
          isClearingCache = false
        }
      }
    }
  }
  
  private func calculateCacheSize() {
    Task {
      do {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let tempFiles = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: [.fileSizeKey])
        let documentFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.fileSizeKey])
        
        let videoExtensions = ["mp4", "mov", "m4v"]
        let filesToCount = (tempFiles + documentFiles).filter { url in
          let isVideo = videoExtensions.contains(url.pathExtension.lowercased())
          let isTempFile = url.lastPathComponent.hasPrefix("temp_") || url.lastPathComponent.hasSuffix(".tmp")
          return isVideo || isTempFile
        }
        
        var totalSize: UInt64 = 0
        for fileURL in filesToCount {
          if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
             let fileSize = resourceValues.fileSize {
            totalSize += UInt64(fileSize)
          }
        }
        
        let sizeInMB = Double(totalSize) / 1_048_576.0
        await MainActor.run {
          cacheSize = String(format: "%.1f MB", sizeInMB)
        }
      } catch {
        await MainActor.run {
          cacheSize = "Error"
        }
      }
    }
  }
  
  private func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
  }
}

struct SectionHeader: View {
  let title: String
  
  var body: some View {
    Text(title)
      .font(Typography.headline)
      .foregroundColor(.gray)
      .padding(.top, 8)
  }
}

struct SettingButton: View {
  let title: String
  let icon: String
  var extraText: String? = nil
  var action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(icon)
        Text(title)
          .foregroundColor(.white)
        Spacer()
        if let extraText = extraText {
          Text(extraText)
            .foregroundColor(.gray)
            .font(.footnote)
        }
        Image(systemName: "chevron.right")
          .foregroundColor(ColorPalette.Accent.primary)
      }
      .padding()
      .background(ColorPalette.Background.primaryAlpha)
      .cornerRadius(12)
    }
  }
}

struct ProBadgeButton: View {
  var isCompact: Bool = false
  @State private var showPaywall = false
  @ObservedObject var subscriptionManager = SubscriptionManager.shared
  
  var body: some View {
    if !subscriptionManager.isSubscribed {
      Button(action: { showPaywall = true }) {
        if isCompact {
          Image(systemName: "sparkles")
            .foregroundColor(.black)
            .padding(10)
            .background(GradientStyle.background)
            .clipShape(Circle())
        } else {
          HStack(spacing: 6) {
            Text("PRO")
              .font(Typography.subheadlineEmphasized)
              .foregroundColor(.black)
            Image(systemName: "sparkles")
              .foregroundColor(.black)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(GradientStyle.background)
          .cornerRadius(16)
        }
      }
      .fullScreenCover(isPresented: $showPaywall) {
        PaywallView()
      }
    }
  }
}

#Preview {
  SettingsView()
}
