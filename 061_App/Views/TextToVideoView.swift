import SwiftUI

struct TextToVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @StateObject private var apiManager = HailuoManager.shared
    @State private var showGeneratingView = false
    @State private var timer: Timer?
    @State private var showResultView = false
    @State private var generatedVideoUrl: String?
    @State private var isGenerating = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            // 🔹 Верхняя панель с заголовком
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ColorPalette.Accent.primary)
                }

                Spacer()

                Text("Create")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal)

            // 🔹 Текстовый редактор с фоном
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(height: UIScreen.main.bounds.height / 2)
                    .padding(10)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal)

                if text.isEmpty {
                    Text("Enter any query to create your video using AI")
                        .foregroundColor(.gray)
                        .padding(.leading, 30)
                        .padding(.top, 18)
                        .allowsHitTesting(false)
                }

                // Кнопка очистки текста
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white.opacity(0.7))
                            .padding(10)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .offset(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height / 2 - 35 )
                }
            }
            .padding(.top, 20)

            Spacer()

            // 🔹 Кнопка генерации
            Button(action: {
                showGeneratingView = true
                startGeneration()
            }) {
                Text("Create")
                    .font(.headline)
                    .foregroundColor( text.isEmpty ? ColorPalette.Label.quintuple : .black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        text.isEmpty ?
                        GradientStyle.gray :
                          GradientStyle.background
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(text.isEmpty)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .fullScreenCover(isPresented: $showGeneratingView) {
            GeneratingView(text: text)
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }
    
    private func startGeneration() {
        Task {
            do {
                isGenerating = true
                let response = try await apiManager.generateTextToVideo(promptText: text) { result in
                    if result.error {
                        error = result.messages.first ?? "Unknown error occurred"
                    } else {
                        startCheckingStatus()
                    }
                }
            } catch {
                self.error = error.localizedDescription
                isGenerating = false
            }
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
    TextToVideoView()
}
