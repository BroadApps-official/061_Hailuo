import SwiftUI
import StoreKit
import UserNotifications

struct SettingsView: View {
    @State private var isNotificationsEnabled = UserDefaults.standard.bool(forKey: "isNotification")
    @State private var isScrolled = false
    @State private var cacheSize: String = "Calculating..."

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Settings")
                            .font(Typography.title2Emphasized)
                            .foregroundColor(.white)
                            .opacity(isScrolled ? 0 : 1)
                        Spacer()
                        ProBadgeButton()
                            .scaleEffect(isScrolled ? 0.8 : 1.0)
                    }
                    .padding(.bottom, 16)

                    SectionHeader(title: "Support us")
                    SettingButton(title: "Rate app", icon: "set1", action: rateApp)
                    SettingButton(title: "Share with friends", icon: "set2", action: shareApp)
                    SectionHeader(title: "Purchases & Actions")
                    SettingButton(title: "Upgrade plan", icon: "set3", action: upgradePlan)
                    ToggleSetting(title: "Notifications", icon: "set4", isOn: $isNotificationsEnabled, action: toggleNotifications)
                    SettingButton(title: "Clear cache", icon: "set5", extraText: cacheSize, action: clearCache)
                    SettingButton(title: "Restore purchases", icon: "set6", action: restorePurchases)
                    SectionHeader(title: "Info & legal")
                    SettingButton(title: "Contact us", icon: "set7", action: contactSupport)
                    SettingButton(title: "Privacy Policy", icon: "set8", action: openPrivacyPolicy)
                    SettingButton(title: "Usage Policy", icon: "set9", action: openUsagePolicy)

                    Text("App Version: 1.0.0")
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
                calculateCacheSize()
            }
        }
    }

    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func shareApp() {
        let appURL = "https://apps.apple.com/app/id6737900240"
        let shareText = "Check out this app!\n\(appURL)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }

    private func upgradePlan() {
        print("Open paywall for upgrading plan")
    }

    private func restorePurchases() {
        print("Restoring purchases...")
        // Добавить логику восстановления покупок
    }

    private func toggleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    isNotificationsEnabled.toggle()
                    UserDefaults.standard.setValue(isNotificationsEnabled, forKey: "isNotification")
                case .denied:
                    print("Notifications disabled in settings")
                    isNotificationsEnabled = false
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            isNotificationsEnabled = granted
                            UserDefaults.standard.setValue(granted, forKey: "isNotification")
                        }
                    }
                default:
                    break
                }
            }
        }
    }

    private func contactSupport() {
        let email = "support@example.com"
        let subject = "Support Request"
        let body = "Hello, I need help with..."
        let emailURL = "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: emailURL) {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://www.privacypolicy.com") {
            UIApplication.shared.open(url)
        }
    }

    private func openUsagePolicy() {
        if let url = URL(string: "https://www.usagepolicy.com") {
            UIApplication.shared.open(url)
        }
    }

    private func clearCache() {
        print("Clearing cache...")
        // Здесь можно добавить логику очистки кэша
        cacheSize = "0 MB"
    }

    private func calculateCacheSize() {
        DispatchQueue.global(qos: .background).async {
            // Заглушка расчета кэша
            let totalSize = Double.random(in: 1...50)
            DispatchQueue.main.async {
                cacheSize = String(format: "%.1f MB", totalSize)
            }
        }
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

struct ToggleSetting: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    var action: () -> Void

    var body: some View {
        HStack {
            Image(icon)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn, perform: { _ in action() })
        }
        .padding()
        .background(ColorPalette.Background.primaryAlpha)
        .cornerRadius(12)
    }
}

struct ProBadgeButton: View {
    var isCompact: Bool = false

    var body: some View {
        Button(action: {}) {
            if isCompact {
                Image(systemName: "sparkles")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(GradientStyle.background)
                    .clipShape(Circle()) // Круглая кнопка
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
    }
}

#Preview {
    SettingsView()
}
