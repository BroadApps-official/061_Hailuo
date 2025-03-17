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
    @State private var isGenerating = true
    @State private var error: String?
    @State private var lastGenerationId: String?

    init(imageData: Data? = nil, text: String? = nil, effectId: String? = nil) {
        self.imageData = imageData
        self.text = text
        self.effectId = effectId
    }

    var body: some View {
        VStack(spacing: 20) {
          Spacer()
            LottieView(animationName: "animation")
              .frame(width: 166, height: 235)
            Text("Creating a video...")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Generation usually takes about a minute")
                .foregroundColor(.white)
          Spacer()
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
                    // Получаем список генераций
                    let generations = try await HailuoManager.shared.fetchUserGenerations()
                    if let lastGeneration = generations.last {
                        print("✅ Найдена последняя генерация: ID \(lastGeneration.id), статус \(lastGeneration.status)")
                        lastGenerationId = String(lastGeneration.id)
                        print("🚀 Запускаем проверку статуса...")
                        startCheckingStatus()
                    } else {
                        error = "Не удалось найти последнюю генерацию"
                    }
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

  @MainActor
  private func checkGenerationStatus(for generationId: String) async {
      print("🔍 [API CALL] Проверяем статус генерации для ID: \(generationId)")

      do {
          // Используем HailuoManager
          let generations = try await HailuoManager.shared.fetchUserGenerations()
          print("📥 [HAILUO RESPONSE] Получен ответ от сервера")

          // Находим самую новую генерацию (по наибольшему `id`)
          if let lastGeneration = generations.max(by: { $0.id < $1.id }) {
              print("✅ Найдена самая новая генерация: ID \(lastGeneration.id), статус \(lastGeneration.status)")

              switch lastGeneration.status {
              case 1, 2:
                  print("⏳ Генерация еще идет, ждем...")

              case 4:
                  print("🚨 Ошибка: статус 4 (ошибка генерации)")
                  timer?.invalidate()
                  timer = nil
                  isGenerating = false
                  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                      dismiss() // Закрываем `GeneratingView` и возвращаемся на `MainContentView`
                  }

              case 3:
                  if let resultUrl = lastGeneration.result {
                      timer?.invalidate()
                      timer = nil
                      generatedVideoUrl = resultUrl
                      showResultView = true
                      isGenerating = false
                      print("🎉 Видео сгенерировано: \(resultUrl)")
                  } else {
                      print("⚠️ Ошибка: статус '3', но URL видео отсутствует!")
                  }

              default:
                  print("❓ Неизвестный статус: \(lastGeneration.status)")
              }
          } else {
              print("⚠️ Подходящая генерация не найдена в списке")
          }
      } catch {
          self.error = error.localizedDescription
          print("❌ [API ERROR] Ошибка при проверке статуса генерации: \(error.localizedDescription)")
      }
  }
}

#Preview {
    GeneratingView(imageData: Data(), effectId: "test")
}
