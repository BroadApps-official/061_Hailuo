import SwiftUI
import AVKit

struct VideoLoopPlayerWithLoading: UIViewControllerRepresentable {
  let url: URL
  @Binding var isLoaded: Bool
  let effectId: Int

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let player: AVQueuePlayer
    let playerItem: AVPlayerItem

    if let cachedData = CoreDataManager.shared.getCachedVideoData(for: effectId) {
      let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(effectId).mp4")
      do {
        try cachedData.write(to: tempURL)
        player = AVQueuePlayer(url: tempURL)
        playerItem = AVPlayerItem(url: tempURL)
      } catch {
        player = AVQueuePlayer(url: url)
        playerItem = AVPlayerItem(url: url)
      }
    } else {
      player = AVQueuePlayer(url: url)
      playerItem = AVPlayerItem(url: url)

      URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
          CoreDataManager.shared.cacheEffect(
            Effect(id: effectId, title: "", preview: url.absoluteString, previewSmall: url.absoluteString),
            videoData: data
          )
        }
      }.resume()
    }

    let looper = AVPlayerLooper(player: player, templateItem: playerItem)
    player.isMuted = true

    let playerViewController = AVPlayerViewController()
    playerViewController.player = player
    playerViewController.showsPlaybackControls = false

    context.coordinator.playerLooper = looper
    context.coordinator.player = player
    context.coordinator.effectId = effectId

    DispatchQueue.main.async {
      isLoaded = true
    }

    player.play()
    return playerViewController
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    if !isLoaded {
      if let cachedData = CoreDataManager.shared.getCachedVideoData(for: context.coordinator.effectId) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(context.coordinator.effectId).mp4")
        do {
          try cachedData.write(to: tempURL)
          let playerItem = AVPlayerItem(url: tempURL)
          context.coordinator.player?.replaceCurrentItem(with: playerItem)
        } catch {
          let playerItem = AVPlayerItem(url: url)
          context.coordinator.player?.replaceCurrentItem(with: playerItem)
        }
      } else {
        let playerItem = AVPlayerItem(url: url)
        context.coordinator.player?.replaceCurrentItem(with: playerItem)
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    var playerLooper: AVPlayerLooper?
    var player: AVQueuePlayer?
    var effectId: Int = 0

    deinit {
      playerLooper?.disableLooping()
      player?.pause()
      player = nil
      playerLooper = nil
    }
  }
}

struct VideoLoopPlayer: UIViewControllerRepresentable {
  let url: URL
  @Binding var isLoading: Bool

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let player = AVQueuePlayer()
    let playerItem = AVPlayerItem(url: url)
    let looper = AVPlayerLooper(player: player, templateItem: playerItem)

    let playerViewController = AVPlayerViewController()
    playerViewController.player = player
    playerViewController.showsPlaybackControls = false

    context.coordinator.playerLooper = looper
    context.coordinator.player = player

    if #available(iOS 16.0, *) {
      Task {
        do {
          try await playerItem.asset.load(.isPlayable)
          DispatchQueue.main.async {
            self.isLoading = false
            player.play()
          }
        } catch {
          print("Error loading video: \(error)")
        }
      }
    } else {
      playerItem.asset.loadValuesAsynchronously(forKeys: ["playable"]) {
        DispatchQueue.main.async {
          self.isLoading = false
          player.play()
        }
      }
    }

    return playerViewController
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    var playerLooper: AVPlayerLooper?
    var player: AVQueuePlayer?
  }
}
