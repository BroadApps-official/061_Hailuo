import SwiftUI

struct GeneratingView: View {
    let imageData: Data?
    let text: String?
    let effectId: String?
    @StateObject private var apiManager = HailuoManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var timer: Timer?
    @State private var showResultView = false
    @State private var generatedVideoUrl: String?
    @State private var isGenerating = false
    @State private var error: String?
    
    init(imageData: Data? = nil, text: String? = nil, effectId: String? = nil) {
        self.imageData = imageData
        self.text = text
        self.effectId = effectId
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок
            Text("Generating your video")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Индикатор загрузки
            if isGenerating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Текст статуса
            Text(isGenerating ? "Please wait..." : "Done!")
                .foregroundColor(.white)
            
            // Кнопка закрытия
            if !isGenerating {
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
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
                dismiss()
            }
        } message: {
            if let error = error {
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
        isGenerating = true
        do {
            if let imageData = imageData, let effectId = effectId {
                let response = try await apiManager.generateVideo(from: imageData, filterId: effectId)
                if response.error {
                    error = response.messages.first ?? "Unknown error occurred"
                } else {
                    startCheckingStatus()
                }
            } else if let text = text {
                let response = try await apiManager.generateTextToVideo(promptText: text) { result in
                    if result.error {
                        error = result.messages.first ?? "Unknown error occurred"
                    } else {
                        startCheckingStatus()
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
            isGenerating = false
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
            let generations = try await apiManager.fetchGenerationStatus()
            
            // ✅ Берем самый последний элемент (тот, у которого `id` наибольший)
            if let latestGeneration = generations.max(by: { $0.id < $1.id }) {
                
                switch latestGeneration.status {
                case 0, 1, 2:
                    print("⏳ Генерация еще идет, ждем...")
                    return
                    
                case 3:
                    if let videoUrl = latestGeneration.result {
                        timer?.invalidate()
                        timer = nil
                        generatedVideoUrl = videoUrl
                        showResultView = true
                        isGenerating = false
                        print("🎉 Видео сгенерировано: \(videoUrl)")
                    } else {
                        print("⚠️ Ошибка: статус 3, но URL видео отсутствует!")
                    }
                    
                case 4:
                    timer?.invalidate()
                    timer = nil
                    error = "❌ Ошибка генерации. Попробуйте снова."
                    isGenerating = false
                    print("🚨 Ошибка: генерация не удалась.")
                    
                default:
                    print("❓ Неизвестный статус: \(latestGeneration.status)")
                }
            } else {
                print("⚠️ Список генераций пуст, ждем обновления...")
            }
            
        } catch {
            self.error = error.localizedDescription
            print("❌ Ошибка при проверке статуса генерации: \(error.localizedDescription)")
        }
    }
}

#Preview {
    GeneratingView(imageData: Data(), effectId: "test")
}
