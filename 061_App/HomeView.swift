import SwiftUI
import AVKit

class TabManager: ObservableObject {
  @Published var selectedTab: Int = 0
}

struct HomeView: View {
    @StateObject var tabManager = TabManager()
    @StateObject private var effectsViewModel = EffectsViewModel() // 👈 Создаем здесь

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            MainContentView()
                .environmentObject(tabManager)
                .environmentObject(effectsViewModel) // 👈 Передаем внутрь
                .tabItem {
                    VStack {
                        Image(tabManager.selectedTab == 0 ? "tab1select" : "tab1")
                    }
                }
                .tag(0)

            MineView()
                .environmentObject(tabManager)
                .tabItem {
                    VStack {
                        Image(tabManager.selectedTab == 1 ? "tab2select" : "tab2")
                    }
                }
                .tag(1)

            SettingsView()
                .environmentObject(tabManager)
                .tabItem {
                    VStack {
                        Image(tabManager.selectedTab == 2 ? "tab3select" : "tab3")
                    }
                }
                .tag(2)
        }
        .tint(.white)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .black
            
            // Добавляем разделитель сверху
            appearance.shadowColor = UIColor(white: 0.2, alpha: 1.0)
            appearance.shadowImage = UIImage()
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
