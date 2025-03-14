import SwiftUI

struct ResultView: View {
    let videoUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 20) {
            // Заголовок
            Text("Your video is ready!")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Видео плеер
          VideoLoopPlayer(url: URL(string: videoUrl)!, isLoading: $isLoading)
                .frame(height: 400)
                .cornerRadius(12)
            
            // Кнопка закрытия
            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    ResultView(videoUrl: "https://example.com/video.mp4")
} 
