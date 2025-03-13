import SwiftUI
import AVKit

struct EffectDetailView: View {
    let selectedEffect: Effect
    let effects: [Effect]
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Горизонтальный скролл эффектов
            TabView(selection: $currentIndex) {
                ForEach(effects.indices, id: \.self) { index in
                    EffectPreviewView(
                        effect: effects[index],
                        previousEffect: effects[safe: index - 1],
                        nextEffect: effects[safe: index + 1],
                        isFocused: index == currentIndex
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.height * 0.7)
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            withAnimation {
                                currentIndex = max(0, currentIndex - 1)
                            }
                        } else if value.translation.width < -threshold {
                            withAnimation {
                                currentIndex = min(effects.count - 1, currentIndex + 1)
                            }
                        }
                    }
            )

            // Кнопка Try effect
            NavigationLink(destination: ImageToVideoView(effects: effects, selectedEffect: selectedEffect)) {
                Text("Try effect")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [.purple, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 10)

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(effects[currentIndex].title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            if let firstIndex = effects.firstIndex(where: { $0.id == selectedEffect.id }) {
                currentIndex = firstIndex
            }
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
