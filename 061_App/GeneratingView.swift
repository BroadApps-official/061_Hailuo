import SwiftUI

struct GeneratingView: View {
    let imageData: Data
    let effectId: String
    @StateObject private var apiManager = HailuoManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var timer: Timer?
    @State private var showResultView = false
    @State private var generatedVideoUrl: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок
            Text("Generating your video")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Индикатор загрузки
            if apiManager.isGenerating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Текст статуса
            Text(apiManager.isGenerating ? "Please wait..." : "Done!")
                .foregroundColor(.white)
            
            // Кнопка закрытия
            if !apiManager.isGenerating {
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
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            await generateVideo()
        }
        .alert("Error", isPresented: .constant(apiManager.error != nil)) {
            Button("OK") {
                apiManager.error = nil
                dismiss()
            }
        } message: {
            if let error = apiManager.error {
                Text(error)
            }
        }
        .fullScreenCover(isPresented: $showResultView) {
            if let videoUrl = generatedVideoUrl {
                ResultView(videoUrl: videoUrl)
            }
        }
    }
    
    private func generateVideo() async {
        apiManager.isGenerating = true
        do {
            let response = try await apiManager.generateVideo(from: imageData, filterId: effectId)
            if response.error {
                apiManager.error = response.messages.first ?? "Unknown error occurred"
            } else {
                // Начинаем периодическую проверку статуса
                startCheckingStatus()
            }
        } catch {
            apiManager.error = error.localizedDescription
        }
    }
    
    private func startCheckingStatus() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task {
                await checkGenerationStatus()
            }
        }
    }
    
  private func checkGenerationStatus() async {
      do {
          await apiManager.fetchUserGenerations()
          if let latestGeneration = apiManager.userGenerations.first(where: { $0.status == 3 }), 
             let videoUrl = latestGeneration.result {
              timer?.invalidate()
              timer = nil
              generatedVideoUrl = videoUrl
              showResultView = true
              apiManager.isGenerating = false
          }
      } catch {
          apiManager.error = error.localizedDescription
      }
  }

}

#Preview {
    GeneratingView(imageData: Data(), effectId: "test")
}
