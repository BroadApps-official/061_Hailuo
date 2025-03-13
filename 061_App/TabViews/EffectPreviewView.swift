import SwiftUI
import AVKit

struct EffectPreviewView: View {
    let effect: Effect
    let previousEffect: Effect?
    let nextEffect: Effect?
    var isFocused: Bool
    @State private var currentPlayer: AVPlayer?
    @State private var previousPlayer: AVPlayer?
    @State private var nextPlayer: AVPlayer?
    @State private var currentScale: CGFloat = 2.0
    @State private var sideScale: CGFloat = 2.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Предыдущее видео
                if let previousEffect = previousEffect {
                    VideoPreviewView(videoURL: previousEffect.preview, effectId: previousEffect.id, player: $previousPlayer)
                        .frame(width: UIScreen.main.bounds.width * 0.15, height: UIScreen.main.bounds.height * 0.45)
                        .scaleEffect(sideScale)
                        .cornerRadius(12)
                        .clipped()
                        .mask(Rectangle().frame(width: UIScreen.main.bounds.width * 0.22, height: UIScreen.main.bounds.height * 0.6))
                        .opacity(0.7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sideScale)
                }

                // Центральное видео (квадратное)
                VideoPreviewView(videoURL: effect.preview, effectId: effect.id, player: $currentPlayer)
                    .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
                    .scaleEffect(currentScale)
                    .cornerRadius(12)
                    .clipped()
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentScale)

                // Следующее видео
                if let nextEffect = nextEffect {
                    VideoPreviewView(videoURL: nextEffect.preview, effectId: nextEffect.id, player: $nextPlayer)
                        .frame(width: UIScreen.main.bounds.width * 0.15, height: UIScreen.main.bounds.height * 0.45)
                        .scaleEffect(sideScale)
                        .cornerRadius(12)
                        .clipped()
                        .mask(Rectangle().frame(width: UIScreen.main.bounds.width * 0.22, height: UIScreen.main.bounds.height * 0.6))
                        .opacity(0.7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sideScale)
                }
            }
            .padding(.horizontal, 10)

            // Индикатор страниц
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(isFocused && index == 1 ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
        }
        .onAppear {
            setupPlayers()
            updateScales()
        }
        .onChange(of: isFocused) { newValue in
            updateScales()
        }
        .onDisappear {
            stopAllPlayers()
        }
    }
    
    private func updateScales() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentScale = isFocused ? 2.0 : 1.8
            sideScale = isFocused ? 1.8 : 2.0
        }
    }

    private func setupPlayers() {
        if let url = URL(string: effect.preview) {
            currentPlayer = AVPlayer(url: url)
            currentPlayer?.play()
        }

        if let previousEffect = previousEffect,
           let url = URL(string: previousEffect.preview) {
            previousPlayer = AVPlayer(url: url)
            previousPlayer?.play()
        }

        if let nextEffect = nextEffect,
           let url = URL(string: nextEffect.preview) {
            nextPlayer = AVPlayer(url: url)
            nextPlayer?.play()
        }
    }

    private func stopAllPlayers() {
        currentPlayer?.pause()
        previousPlayer?.pause()
        nextPlayer?.pause()
    }
}

struct VideoPreviewView: View {
    let videoURL: String
    let effectId: Int
    @Binding var player: AVPlayer?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                        isLoading = false
                    }
            }
            
            if isLoading {
                ProgressView()
                    .onAppear {
                        loadVideo()
                    }
            }
            
            if let error = error {
                Text("Error loading video")
                    .foregroundColor(.red)
                    .onAppear {
                        loadVideo()
                    }
            }
        }
        .clipped()
    }
    
    private func loadVideo() {
        // Сначала проверяем кэш
        if let cachedData = CoreDataManager.shared.getCachedVideoData(for: effectId) {
            createPlayer(from: cachedData)
            return
        }
        
        // Если нет в кэше, загружаем из сети
        guard let url = URL(string: videoURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
                return
            }
            
            guard let data = data else { return }
            
            // Сохраняем в кэш
            CoreDataManager.shared.cacheEffect(Effect(id: effectId, title: "", preview: videoURL, previewSmall: videoURL), videoData: data)
            
            DispatchQueue.main.async {
                self.createPlayer(from: data)
            }
        }.resume()
    }
    
    private func createPlayer(from data: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(effectId).mp4")
        
        do {
            try data.write(to: tempURL)
            player = AVPlayer(url: tempURL)
            player?.play()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}
