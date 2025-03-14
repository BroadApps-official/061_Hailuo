import SwiftUI

struct GeneratingView: View {
    let imageData: Data?
    let text: String?
    let effectId: String?

    @StateObject private var apiManager = APIManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var timer: Timer?
    @State private var showResultView = false
    @State private var generatedVideoUrl: String?
    @State private var isGenerating = false
    @State private var error: String?
    @State private var lastGenerationId: String?

    init(imageData: Data? = nil, text: String? = nil, effectId: String? = nil) {
        self.imageData = imageData
        self.text = text
        self.effectId = effectId
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Generating your video")
                .font(.title2.bold())
                .foregroundColor(.white)

            if isGenerating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }

            Text(isGenerating ? "Please wait..." : "Done!")
                .foregroundColor(.white)

            if !isGenerating {
                Button(action: { dismiss() }) {
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
                ResultView(videoUrl: videoUrl, promptText: text)
            }
        }
    }

    private func generateVideo() async {
        isGenerating = true
        do {
            if let imageData = imageData, let effectId = effectId {
                let response = try await HailuoManager.shared.generateVideo(from: imageData, filterId: effectId)
                if response.error {
                    error = response.messages.first ?? "Unknown error occurred"
                } else {
                    print("🚀 Запускаем проверку статуса...")
                    startCheckingStatus()
                }
            } else if let text = text, let imageData = imageData, let imageUrl = saveImageToTempDirectory(imageData) {
                print("📸 Запускаем `generatePikaScenes`...")
              apiManager.generatePikaScenes(imageUrls: [imageUrl], promptText: text) { result in
                              handleGenerationResult(result)
                          }
            } else if let text = text {
                print("📝 Запускаем `generateTextToVideo`...")
                apiManager.generateTextToVideo(promptText: text) { result in
                    handleGenerationResult(result)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
                self.isGenerating = false
            }
        }
    }

  private func saveImageToTempDirectory(_ imageData: Data) -> URL? {
      let tempDirectory = FileManager.default.temporaryDirectory
      let fileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).jpg")

      do {
          try imageData.write(to: fileURL)
          print("✅ Изображение сохранено во временной директории: \(fileURL)")
          return fileURL
      } catch {
          print("❌ Ошибка сохранения изображения: \(error.localizedDescription)")
          return nil
      }
  }

    private func handleGenerationResult(_ result: Result<String, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let generationId):
                print("✅ Генерация запущена, ID: \(generationId)")
                lastGenerationId = generationId
                print("🚀 Запускаем проверку статуса...")
                startCheckingStatus()

            case .failure(let apiError):
                error = apiError.localizedDescription
                isGenerating = false
                print("🚨 Ошибка генерации: \(apiError.localizedDescription)")
            }
        }
    }

    private func startCheckingStatus() {
        guard let generationId = lastGenerationId else {
            print("❌ Ошибка: lastGenerationId не установлен! Таймер НЕ запустится.")
            return
        }

        print("⏳ Запускаем таймер для ID: \(generationId)")

        DispatchQueue.main.async {
            self.timer?.invalidate()
            print("✅ Таймер сброшен, создаем новый...")

            self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                print("🔄 [TIMER] Запрос статуса для ID: \(generationId)...")
                Task {
                    await self.checkGenerationStatus(for: generationId)
                }
            }
            print("🎯 Таймер успешно создан!")
        }
    }

    private func checkGenerationStatus(for generationId: String) async {
        print("🔍 [API CALL] Проверяем статус генерации для ID: \(generationId)")

        apiManager.fetchGenerationStatus(generationId: generationId) { result in
            DispatchQueue.main.async {
                print("📥 [API RESPONSE] Получен ответ от сервера")
                switch result {
                case .success(let statusResponse):
                    print("✅ [SUCCESS] Статус генерации: \(statusResponse)")

                    guard let response = statusResponse as? GenerationStatusResponse else {
                        print("❌ [ERROR] API вернул неожиданный формат данных")
                        return
                    }

                    switch response.status {
                    case "processing", "queued", "pending":
                        print("⏳ Генерация еще идет, ждем...")

                    case "finished":
                        if let videoUrl = response.resultUrl {
                            timer?.invalidate()
                            timer = nil
                            generatedVideoUrl = videoUrl
                            showResultView = true
                            isGenerating = false
                            print("🎉 Видео сгенерировано: \(videoUrl)")
                        } else {
                            print("⚠️ Ошибка: статус 'finished', но URL видео отсутствует!")
                        }

                    case "error":
                        timer?.invalidate()
                        timer = nil
                        error = response.error ?? "❌ Ошибка генерации. Попробуйте снова."
                        isGenerating = false
                        print("🚨 Ошибка: генерация не удалась.")

                    default:
                        print("❓ Неизвестный статус: \(response.status)")
                    }

                case .failure(let error):
                    self.error = error.localizedDescription
                    print("❌ [API ERROR] Ошибка при проверке статуса генерации: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    GeneratingView(imageData: Data(), effectId: "test")
}
