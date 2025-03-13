//import SwiftUI
//
//class TabManager: ObservableObject {
//  @Published var selectedTab: Tab = .create
//}
//
//struct CustomTabBarView: View {
//  @StateObject private var tabManager = TabManager()
//  
//  var body: some View {
//    NavigationStack {
//      VStack(spacing: 0) {
//        switch tabManager.selectedTab {
//        case .create: CreateView()
//            .environmentObject(tabManager)
//        case .preset: PresetView()
//            .environmentObject(tabManager)
//        case .project: ProjectView()
//            .environmentObject(tabManager)
//        case .aiAvatar: AIAvatarView(gender: AvatarAPI.shared.gender, uploadedPhotos: [], onComplete: {})
//            .environmentObject(tabManager)
//        }
//        
//        CustomTabBar()
//          .frame(width: UIScreen.main.bounds.width * 1.1, height: 30)
//          .safeAreaInset(edge: .bottom) {
//            ColorTokens.labelGray3.frame(height: 0)
//          }
//      }
//      .background(ColorTokens.labelGray3.edgesIgnoringSafeArea(.all))
//      .environmentObject(tabManager)
//    }
//  }
//}
//
//struct CustomTabBar: View {
//  @EnvironmentObject var tabManager: TabManager
//  
//  var body: some View {
//    VStack(spacing: 0) {
//      HStack {
//        ForEach(Tab.allCases, id: \.self) { tab in
//          Button(action: {
//            withAnimation {
//              tabManager.selectedTab = tab
//            }
//          }) {
//            VStack(spacing: 4) {
//              Image(tabManager.selectedTab == tab ? tab.iconNameFill : tab.iconName)
//                .renderingMode(.original)
//            }
//            .frame(maxWidth: .infinity)
//          }
//        }
//      }
//      .padding(.vertical, 10)
//      .background(ColorTokens.labelGray3)
//      .cornerRadius(30)
//      .padding(.horizontal, 16)
//    }
//  }
//}
//
//enum Tab: CaseIterable {
//  case create, preset, project, aiAvatar
//  
//  var iconName: String {
//    switch self {
//    case .create: return "tab1-off"
//    case .preset: return "tab2-off"
//    case .project: return "tab3-off"
//    case .aiAvatar: return "tab4-off"
//    }
//  }
//  
//  var iconNameFill: String {
//    switch self {
//    case .create: return "tab1-on"
//    case .preset: return "tab2-on"
//    case .project: return "tab3-on"
//    case .aiAvatar: return "tab4-on"
//    }
//  }
//}
//
