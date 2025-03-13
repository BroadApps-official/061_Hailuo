import SwiftUI

struct MineView: View {
    @State private var selectedTab = 0
    private let tabs = ["All videos (5)", "My favorites (1)"]

    var body: some View {
        VStack {
            // Навигационный бар
            HStack {
                Text("Mine")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                ProBadgeButton()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Переключение вкладок
            HStack(spacing: 12) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: { selectedTab = index }) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedTab == index ? .black : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTab == index ? Color.white : Color.black.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Список видео
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionView(date: "06.03.2025", videos: [
                        VideoItem(isLoading: true),
                        VideoItem(imageName: "video1")
                    ])

                    SectionView(date: "04.03.2025", videos: [
                        VideoItem(imageName: "video2")
                    ])
                }
                .padding(.horizontal)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .tabBar()
    }
}

// Компонент для заголовка даты и списка видео
struct SectionView: View {
    let date: String
    let videos: [VideoItem]

    var body: some View {
        VStack(alignment: .leading) {
            Text(date)
                .font(.system(size: 14))
                .foregroundColor(.gray)

            ForEach(videos.indices, id: \.self) { index in
                videos[index]
            }
        }
    }
}

// Компонент видео-элемента
struct VideoItem: View {
    var imageName: String? = nil
    var isLoading: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Video is generated...")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    )
            } else if let imageName = imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay(
                        Button(action: {}) {
                            Image(systemName: "bookmark.fill")
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            }
        }
    }
}

// Добавление таббара
extension View {
    func tabBar() -> some View {
        self
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        TabBarItem(icon: "wand.and.stars", title: "Create", isSelected: false)
                        Spacer()
                        TabBarItem(icon: "square.stack", title: "Mine", isSelected: true)
                        Spacer()
                        TabBarItem(icon: "gearshape", title: "Settings", isSelected: false)
                    }
                    .padding(.horizontal, 30)
                    .frame(height: 64)
                    .background(Color.black)
                }
                .edgesIgnoringSafeArea(.bottom)
            )
    }
}

// Компонент иконки таббара
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .purple : .gray)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? .purple : .gray)
        }
    }
}

#Preview {
    MineView()
}
