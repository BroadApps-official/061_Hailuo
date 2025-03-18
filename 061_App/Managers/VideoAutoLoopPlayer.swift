import SwiftUI
import AVKit

struct VideoLoopPlayerWithLoading: UIViewControllerRepresentable {
  let url: URL
  @Binding var isLoaded: Bool
  let effectId: Int

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let playerViewController = AVPlayerViewController()
    playerViewController.showsPlaybackControls = false

    let cachedFileURL = getCachedFileURL()

    if FileManager.default.fileExists(atPath: cachedFileURL.path) {
      setupPlayer(with: cachedFileURL, playerViewController: playerViewController, context: context)
    } else if let cachedData = CoreDataManager.shared.getCachedVideoData(for: effectId) {
      do {
        try cachedData.write(to: cachedFileURL)
        setupPlayer(with: cachedFileURL, playerViewController: playerViewController, context: context)
      } catch {
        setupPlayer(with: url, playerViewController: playerViewController, context: context)
      }
    } else {
      URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data = data else { return }

        CoreDataManager.shared.cacheEffect(
          Effect(id: effectId, title: "", preview: url.absoluteString, previewSmall: url.absoluteString),
          videoData: data
        )

        do {
          try data.write(to: cachedFileURL)
          DispatchQueue.main.async {
            setupPlayer(with: cachedFileURL, playerViewController: playerViewController, context: context)
          }
        } catch {
          DispatchQueue.main.async {
            setupPlayer(with: url, playerViewController: playerViewController, context: context)
          }
        }
      }.resume()
    }

    return playerViewController
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  private func setupPlayer(with videoURL: URL, playerViewController: AVPlayerViewController, context: Context) {
    let playerItem = AVPlayerItem(url: videoURL)
    let player = AVQueuePlayer(playerItem: playerItem)
    let looper = AVPlayerLooper(player: player, templateItem: playerItem)

    player.isMuted = true
    player.play()

    context.coordinator.playerLooper = looper
    context.coordinator.player = player

    DispatchQueue.main.async {
      isLoaded = true
    }

    playerViewController.player = player
  }

  private func getCachedFileURL() -> URL {
    let fileName = "\(effectId).mp4"
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return documentsDir.appendingPathComponent(fileName)
  }

  class Coordinator {
    var playerLooper: AVPlayerLooper?
    var player: AVQueuePlayer?

    deinit {
      playerLooper?.disableLooping()
      player?.pause()
      player = nil
      playerLooper = nil
    }
  }
}
