import SwiftUI
import AdSupport
import AppTrackingTransparency
import CoreData
import ApphudSDK
import UserNotifications

@main
struct MyApp: App {
  @AppStorage("videoGenerationCount") private var videoGenerationCount = 0
  @AppStorage("appLaunchCount") private var appLaunchCount = 0
  @AppStorage("hasRatedApp") private var hasRatedApp = false
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
  
  @State private var showReviewSheet = false
  @State private var showOnboarding = false
  
  @StateObject var networkMonitor = NetworkMonitor.shared
  @StateObject var tabManager = TabManager()
  
  let persistenceController = CoreDataManager.shared
  
  init() {
    Apphud.start(apiKey: "app_rKfkFGpycLT9wtz4e7jzXFVw4rMLt7")
    Apphud.setDeviceIdentifiers(idfa: nil, idfv: UIDevice.current.identifierForVendor?.uuidString)
    fetchIDFA()
  }
  
  var body: some Scene {
    WindowGroup {
      HomeView()
        .environmentObject(tabManager)
        .environmentObject(networkMonitor)
        .environment(\.managedObjectContext, persistenceController.context)
        .onAppear {
          appLaunchCount += 1
          checkReviewConditions()
          
          if !hasSeenOnboarding {
            showOnboarding = true
          }
        }
        .sheet(isPresented: $showReviewSheet) {
          ReviewRequestView()
        }
    }
  }
  
  func fetchIDFA() {
    if #available(iOS 14.5, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        ATTrackingManager.requestTrackingAuthorization { status in
          guard status == .authorized else { return }
          
          let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
          Apphud.setDeviceIdentifiers(idfa: idfa, idfv: UIDevice.current.identifierForVendor?.uuidString)
        }
      }
    }
  }
  
  private func checkReviewConditions() {
    if !hasRatedApp &&
        (videoGenerationCount == 3 || videoGenerationCount == 6 || appLaunchCount == 3) {
      showReviewSheet = true
    }
  }
}
