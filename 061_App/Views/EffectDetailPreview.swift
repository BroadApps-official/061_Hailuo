//import SwiftUI
//import AVKit
//
//struct EffectDetailPreview: View {
//    let currentEffect: Effect
//    let previousEffect: Effect?
//    let nextEffect: Effect?
//    @State private var currentPlayer: AVPlayer?
//    @State private var previousPlayer: AVPlayer?
//    @State private var nextPlayer: AVPlayer?
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            HStack(spacing: 0) {
//                // Предыдущее видео
//                if let previousEffect = previousEffect {
//                    VideoPreviewView(videoURL: previousEffect.preview, player: $previousPlayer)
//                        .frame(width: UIScreen.main.bounds.width * 0.25)
//                        .frame(height: UIScreen.main.bounds.height * 0.6)
//                        .opacity(0.7)
//                }
//                
//                // Текущее видео
//                VideoPreviewView(videoURL: currentEffect.preview, player: $currentPlayer)
//                    .frame(width: UIScreen.main.bounds.width * 0.5)
//                    .frame(height: UIScreen.main.bounds.height * 0.8)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 12)
//                            .stroke(Color.white, lineWidth: 2)
//                    )
//                
//                // Следующее видео
//                if let nextEffect = nextEffect {
//                    VideoPreviewView(videoURL: nextEffect.preview, player: $nextPlayer)
//                        .frame(width: UIScreen.main.bounds.width * 0.25)
//                        .frame(height: UIScreen.main.bounds.height * 0.6)
//                        .opacity(0.7)
//                }
//            }
//            .navigationTitle(currentEffect.title)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: { dismiss() }) {
//                        Text("<")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
//                }
//            }
//            .toolbarBackground(.black, for: .navigationBar)
//            .toolbarBackground(.visible, for: .navigationBar)
//        }
//        .onAppear {
//            setupPlayers()
//        }
//        .onDisappear {
//            stopAllPlayers()
//        }
//    }
//    
//    private func setupPlayers() {
//        if let url = URL(string: currentEffect.preview) {
//            currentPlayer = AVPlayer(url: url)
//            currentPlayer?.play()
//        }
//        
//        if let previousEffect = previousEffect,
//           let url = URL(string: previousEffect.preview) {
//            previousPlayer = AVPlayer(url: url)
//            previousPlayer?.play()
//        }
//        
//        if let nextEffect = nextEffect,
//           let url = URL(string: nextEffect.preview) {
//            nextPlayer = AVPlayer(url: url)
//            nextPlayer?.play()
//        }
//    }
//    
//    private func stopAllPlayers() {
//        currentPlayer?.pause()
//        previousPlayer?.pause()
//        nextPlayer?.pause()
//    }
//}
//
//struct VideoPreviewView: View {
//    let videoURL: String
//    @Binding var player: AVPlayer?
//    
//    var body: some View {
//        ZStack {
//            if let player = player {
//                VideoPlayer(player: player)
//                    .onAppear {
//                        player.play()
//                    }
//            } else {
//                ProgressView()
//                    .onAppear {
//                        if let url = URL(string: videoURL) {
//                            player = AVPlayer(url: url)
//                        }
//                    }
//            }
//        }
//    }
//}
//
//#Preview {
//    EffectDetailPreview(
//        currentEffect: Effect(id: 1, title: "Current", preview: "https://example.com/current.mp4", previewSmall: ""),
//        previousEffect: Effect(id: 2, title: "Previous", preview: "https://example.com/previous.mp4", previewSmall: ""),
//        nextEffect: Effect(id: 3, title: "Next", preview: "https://example.com/next.mp4", previewSmall: "")
//    )
//} 
