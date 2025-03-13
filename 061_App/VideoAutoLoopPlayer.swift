import SwiftUI
import AVKit

struct VideoLoopPlayerWithLoading: UIViewControllerRepresentable {
    let url: URL
    @Binding var isLoaded: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVQueuePlayer()
        let playerItem = AVPlayerItem(url: url)
        let looper = AVPlayerLooper(player: player, templateItem: playerItem)

        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false

        context.coordinator.playerLooper = looper
        context.coordinator.player = player

        DispatchQueue.main.async {
            isLoaded = true  // ✅ Отмечаем, что видео загружено
        }

        player.play()
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if !isLoaded, let currentItem = uiViewController.player?.currentItem, currentItem.asset != AVAsset(url: url) {
            let playerItem = AVPlayerItem(url: url)
            context.coordinator.player?.replaceCurrentItem(with: playerItem)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var playerLooper: AVPlayerLooper?
        var player: AVQueuePlayer?
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

        // Отслеживаем окончание загрузки видео
        playerItem.asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                self.isLoading = false
                player.play()
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
