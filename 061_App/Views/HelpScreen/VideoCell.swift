import SwiftUI
import AVFoundation

struct VideoCell: View {
  let video: GeneratedVideo
  @State private var thumbnail: UIImage?
  @State private var isCheckingStatus = false
  @State private var isFavorite: Bool

  init(video: GeneratedVideo) {
    self.video = video
    _isFavorite = State(initialValue: GeneratedVideosManager.shared.isFavorite(video))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ZStack {
        if let thumbnail = thumbnail {
          Image(uiImage: thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Color.gray
            .blur(radius: 50)
        }

        if video.status == .generating {
          VStack {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(2.0)
            Text("Video is generating...")
              .foregroundColor(.white)
              .padding(.top, 8)
          }
        } else if video.status == .failed {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 40))
            .foregroundColor(.red)
        }
      }
      .frame(height: 180)
      .cornerRadius(12)
      .contentShape(Rectangle())
      .overlay(alignment: .topTrailing) {
        if video.status == .completed {
          Button(action: {
            toggleFavorite()
          }) {
            Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
              .foregroundColor(.white)
              .font(.system(size: 17, weight: .bold))
              .padding(12)
              .background(Color.black.opacity(0.5))
              .cornerRadius(12)
          }
          .padding(8)
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(video.createdAt, formatter: DateFormatter.customDate)
            .font(.subheadline)
            .foregroundColor(.gray)

          Spacer()
        }
      }
    }
    .onAppear {
      if video.status == .completed, let url = video.resultUrl {
        loadThumbnail(from: url)
      } else if video.status == .generating {
        checkGenerationStatus()
      }
    }
    .onChange(of: video.status) { newStatus in
      if newStatus == .completed, let url = video.resultUrl {
        loadThumbnail(from: url)
      }
    }
    .onDisappear {
      isCheckingStatus = false
    }
  }

  private func toggleFavorite() {
    if isFavorite {
      GeneratedVideosManager.shared.removeFromFavorites(video)
    } else {
      GeneratedVideosManager.shared.addToFavorites(video)
    }
    isFavorite.toggle()
  }

  private func checkGenerationStatus() {
    guard video.status == .generating && !isCheckingStatus else { return }
    isCheckingStatus = true

    Task {
      do {
        let response = try await APIManager.shared.fetchGenerationStatus(generationId: video.generationId)

        switch response.status {
        case "completed", "finished":
          if let videoUrl = response.resultUrl {
            await GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .completed, resultUrl: videoUrl)
            loadThumbnail(from: videoUrl)
          }
        case "error":
          await GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .failed)
        default:
          if video.status == .generating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
              checkGenerationStatus()
            }
          }
        }
      } catch {
        print("❌ Error checking status: \(error.localizedDescription)")
        if video.status == .generating {
          DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            checkGenerationStatus()
          }
        }
      }
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
