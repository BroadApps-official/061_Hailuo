import SwiftUI
import AVKit

struct EffectPreviewView: View {
    let effect: Effect
    let previousEffect: Effect?
    let nextEffect: Effect?
    var isFocused: Bool
    @State private var currentScale: CGFloat = 2.0
    @State private var sideScale: CGFloat = 2.0
    @State private var isCurrentLoaded = false
    @State private var isPreviousLoaded = false
    @State private var isNextLoaded = false
    
    // Кэшируем URL для оптимизации
    private var currentURL: URL? {
        URL(string: effect.preview)
    }
    
    private var previousURL: URL? {
        previousEffect.flatMap { URL(string: $0.preview) }
    }
    
    private var nextURL: URL? {
        nextEffect.flatMap { URL(string: $0.preview) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Предыдущее видео
                if let previousEffect = previousEffect, let url = previousURL {
                    VideoLoopPlayerWithLoading(url: url, isLoaded: $isPreviousLoaded, effectId: previousEffect.id)
                        .frame(width: UIScreen.main.bounds.width * 0.15, height: UIScreen.main.bounds.height * 0.45)
                        .scaleEffect(sideScale)
                        .cornerRadius(12)
                        .clipped()
                        .mask(Rectangle().frame(width: UIScreen.main.bounds.width * 0.22, height: UIScreen.main.bounds.height * 0.6))
                        .opacity(0.7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sideScale)
                }

                // Центральное видео (квадратное)
                if let url = currentURL {
                    VideoLoopPlayerWithLoading(url: url, isLoaded: $isCurrentLoaded, effectId: effect.id)
                        .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
                        .scaleEffect(currentScale)
                        .cornerRadius(12)
                        .clipped()
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentScale)
                }

                // Следующее видео
                if let nextEffect = nextEffect, let url = nextURL {
                    VideoLoopPlayerWithLoading(url: url, isLoaded: $isNextLoaded, effectId: nextEffect.id)
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
            updateScales()
        }
        .onChange(of: isFocused) { newValue in
            updateScales()
        }
    }
    
    private func updateScales() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentScale = isFocused ? 2.0 : 1.8
            sideScale = isFocused ? 1.8 : 2.0
        }
    }
}
