import SwiftUI

class TabManager: ObservableObject {
  @Published var selectedTab: Int = 0
}

struct CustomTabBarView: View {
  @StateObject var tabManager = TabManager()
  @StateObject private var effectsViewModel = EffectsViewModel()

  var body: some View {
    TabView(selection: $tabManager.selectedTab) {
      MainContentView()
        .environmentObject(tabManager)
        .environmentObject(effectsViewModel)
        .tabItem {
          VStack {
            Image(tabManager.selectedTab == 0 ? "tab1select" : "tab1")
              .foregroundColor(tabManager.selectedTab == 0 ? ColorPalette.Accent.primary : .gray)
          }
        }
        .tag(0)

      MineView()
        .environmentObject(tabManager)
        .tabItem {
          VStack {
            Image(tabManager.selectedTab == 1 ? "tab2select" : "tab2")
              .foregroundColor(tabManager.selectedTab == 1 ? ColorPalette.Accent.primary : .gray)
          }
        }
        .tag(1)

      SettingsView()
        .environmentObject(tabManager)
        .tabItem {
          VStack {
            Image(tabManager.selectedTab == 2 ? "tab3select" : "tab3")
              .foregroundColor(tabManager.selectedTab == 2 ? ColorPalette.Accent.primary : .gray)
          }
        }
        .tag(2)
    }
    .tint(.white)
    .onAppear {
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = .black
      appearance.shadowColor = UIColor(white: 0.2, alpha: 1.0)
      appearance.shadowImage = UIImage()

      UITabBar.appearance().standardAppearance = appearance
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }
  }
}
