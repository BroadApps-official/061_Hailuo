import SwiftUI
import AVFoundation

struct MineView: View {
    @StateObject private var videosManager = GeneratedVideosManager.shared
    @State private var selectedTab = "All videos"

    private let tabs = ["All videos", "My favorites"]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Text("Mine")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {}) {
                        Text("PRO")
                            .font(.caption.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)

              Picker("Tabs", selection: $selectedTab) {
                  ForEach(tabs, id: \.self) { tab in
                      let countText: String = {
                          if tab == "All videos" {
                              return "(\(videosManager.videos.count))"
                          } else {
                              return "(1)" 
                          }
                      }()

                      Text("\(tab) \(countText)")
                          .tag(tab)
                  }
              }
              .pickerStyle(SegmentedPickerStyle())
              .padding(.horizontal)


                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(videosManager.videos) { video in
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    if video.status == .completed, let url = video.resultUrl {
                                        VideoCell(video: video)
                                    } else if video.status == .generating {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(height: 180)
                                            .cornerRadius(12)
                                            .overlay(ProgressView().foregroundColor(.white))
                                    } else {
                                        Rectangle()
                                            .fill(Color.red.opacity(0.5))
                                            .frame(height: 180)
                                            .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)

                                Text(video.createdAt, formatter: DateFormatter.shortDate)
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}

struct VideoCell: View {
    let video: GeneratedVideo
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.black
                }
                
                if video.status == .generating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if video.status == .failed {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                if let prompt = video.promptText {
                    Text(prompt)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(video.createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .onAppear {
            if video.status == .completed, let url = video.resultUrl {
                loadThumbnail(from: url)
            }
        }
    }
    
    private var statusText: String {
        switch video.status {
        case .generating:
            return "Generating..."
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    private var statusColor: Color {
        switch video.status {
        case .generating:
            return .yellow
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    private func loadThumbnail(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
            generateThumbnail(from: cachedURL)
            return
        }
        
        VideoCacheService.shared.cacheVideo(from: url) { cachedURL in
            if let cachedURL = cachedURL {
                generateThumbnail(from: cachedURL)
            }
        }
    }
    
    private func generateThumbnail(from url: URL) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        let times = [NSValue(time: time)]
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnail = UIImage(cgImage: image)
                }
            }
        }
    }
}

private func setupPreviewData() {
    let manager = GeneratedVideosManager.shared
    manager.clearVideos()
    
    let testVideos = [
        GeneratedVideo(
            id: UUID().uuidString,
            generationId: "test1",
            videoUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4",
            promptText: "Красивый закат на море с пальмами",
            createdAt: Date().addingTimeInterval(-3600),
            status: .completed,
            resultUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4"
        ),
        GeneratedVideo(
            id: UUID().uuidString,
            generationId: "test2",
            videoUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4",
            promptText: "Городской пейзаж ночью с неоновыми огнями",
            createdAt: Date().addingTimeInterval(-7200),
            status: .generating,
            resultUrl: nil
        ),
        GeneratedVideo(
            id: UUID().uuidString,
            generationId: "test3",
            videoUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4",
            promptText: "Космический корабль в открытом космосе",
            createdAt: Date().addingTimeInterval(-10800),
            status: .failed,
            resultUrl: nil
        )
    ]
    
    testVideos.forEach { video in
        manager.addVideo(video)
    }
}

#Preview {
    setupPreviewData()
    return MineView()
} 
