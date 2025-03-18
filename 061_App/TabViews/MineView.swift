import SwiftUI
import AVFoundation

struct MineView: View {
  @StateObject private var videosManager = GeneratedVideosManager.shared
  @State private var selectedTab = "All videos"
  @State private var showingDeleteAlert = false
  @State private var videoToDelete: GeneratedVideo?
  @State private var selectedVideo: GeneratedVideo?
  
  private let tabs = ["All videos", "My favorites"]
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Mine")
          .font(Typography.title1Emphasized)
          .foregroundColor(.white)
        
        Spacer()
        
        ProBadgeButton()
      }
      .padding(.horizontal)
      .padding(.vertical)
      
      let filteredVideos = selectedTab == "All videos" ? videosManager.videos : videosManager.favoriteVideos
      if filteredVideos.isEmpty {
        EmptyStateView()
      } else {
        HStack(spacing: 8) {
          ForEach(tabs, id: \.self) { tab in
            let isSelected = selectedTab == tab
            let videoCount = tab == "All videos" ? videosManager.videos.count : videosManager.favoriteVideos.count
            
            Button(action: {
              selectedTab = tab
            }) {
              Text("\(tab) (\(videoCount))")
                .font(Typography.footnote)
                .foregroundColor(isSelected ? .white : ColorPalette.Label.tertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ColorPalette.Background.secondary : ColorPalette.Background.tertiary)
                .cornerRadius(8)
            }
          }
        }
        .padding(.horizontal)
        
        ScrollView {
          LazyVStack(spacing: 20) {
            ForEach(filteredVideos) { video in
              VideoCell(video: video)
                .onTapGesture {
                  if video.status == .completed {
                    selectedVideo = video
                  }
                }
                .contextMenu {
                  Button(role: .destructive) {
                    videoToDelete = video
                    showingDeleteAlert = true
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }
                }
            }
          }
          .padding()
        }
      }
      Spacer()
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .alert("Delete Video", isPresented: $showingDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let video = videoToDelete {
          videosManager.deleteVideo(video)
        }
      }
    } message: {
      Text("Are you sure you want to delete this video?")
    }
    .fullScreenCover(item: $selectedVideo) { video in
      if let url = video.resultUrl {
        ResultView(videoUrl: url, promptText: video.promptText ?? nil)
      }
    }
  }
}

struct EmptyStateView: View {
  @EnvironmentObject private var tabManager: TabManager
  
  var body: some View {
    VStack {
      Spacer()
      
      ZStack {
        Circle()
          .fill(Color.gray.opacity(0.2))
          .frame(width: 100, height: 100)
        
        Image(systemName: "folder.badge.plus")
          .resizable()
          .scaledToFit()
          .frame(width: 60, height: 60)
          .symbolRenderingMode(.palette)
          .foregroundColor(.gray.opacity(0.7))
          .offset(x: 5)
      }
      
      Text("It's empty here")
        .font(.title2.bold())
        .foregroundColor(.white)
        .padding(.top, 10)
      
      Text("Create your first generation")
        .foregroundColor(.gray)
        .font(.subheadline)
      
      Button(action: {
        tabManager.selectedTab = 0
      }) {
        Text("Create")
          .font(.headline)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .padding()
          .background(GradientStyle.background)
          .cornerRadius(12)
      }
      .padding(.horizontal, 10)
      .padding(.top, 20)
      
      Spacer()
    }
  }
}

extension DateFormatter {
  static let customDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy"
    return formatter
  }()
}
