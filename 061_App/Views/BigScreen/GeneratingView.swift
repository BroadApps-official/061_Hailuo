import SwiftUI

struct GeneratingView: View {
  let imageData: Data?
  let text: String?
  let effectId: String?

  @StateObject private var apiManager = APIManager.shared
  @EnvironmentObject private var effectsViewModel: EffectsViewModel
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tabManager: TabManager
  @State private var timer: Timer?
  @State private var showResultView = false
  @State private var generatedVideoUrl: String?
  @State private var isGenerating = true
  @State private var error: String?
  @State private var lastGenerationId: String?
  @State private var resultVideoUrl: String?
  @State private var resultPromptText: String?
  @State private var showErrorAlert = false

  init(imageData: Data? = nil, text: String? = nil, effectId: String? = nil) {
    self.imageData = imageData
    self.text = text
    self.effectId = effectId
  }

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Spacer()
        closeButton
      }
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
        tabManager.selectedTab = 1
      }
    } message: {
      if let error = error {
        Text(error)
      }
    }
    .alert("Error", isPresented: $showErrorAlert) {
      Button("OK") {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          tabManager.selectedTab = 1
        }
      }
    } message: {
      Text(" Error! Try again later.")
    }
    .fullScreenCover(isPresented: $showResultView) {
      if let videoUrl = generatedVideoUrl {
        ResultView(videoUrl: videoUrl, promptText: text)
      }
    }
  }

  private var closeButton: some View {
    Button(action: { 
      dismiss()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        tabManager.selectedTab = 1
      }
    }) {
      Image(systemName: "xmark")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(ColorPalette.Accent.primary)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
  }

  private func generateVideo() async {
    isGenerating = true
    do {
      if let imageData = imageData, let effectId = effectId {
        let response = try await HailuoManager.shared.generateVideo(from: imageData, filterId: effectId)
        if response.error {
          error = response.messages.first ?? "Unknown error occurred"
          return
        }

        var lastGeneration: Generation?
        var attempts = 0
        let maxAttempts = 5
        
        while attempts < maxAttempts {
          let generations = try await HailuoManager.shared.fetchUserGenerations()
          lastGeneration = generations.last(where: { $0.status == 1 || $0.status == 2 })
          
          if lastGeneration != nil {
            print("✅ Found active generation: ID \(lastGeneration!.id), status \(lastGeneration!.status)")
            break
          }
          
          print("⏳ Waiting for active generation... Attempt \(attempts + 1)")
          try await Task.sleep(nanoseconds: 2_000_000_000)
          attempts += 1
        }
        
        if let lastGeneration = lastGeneration {
          lastGenerationId = String(lastGeneration.id)
          DispatchQueue.main.async {
            GeneratedVideosManager.shared.addVideo(
              GeneratedVideo(
                id: UUID().uuidString,
                generationId: String(lastGeneration.id),
                videoUrl: "",
                promptText: text,
                createdAt: Date(),
                status: .generating,
                resultUrl: nil
              )
            )
          }

          await startCheckingStatus()
        } else {
          error = "Failed to start generation after \(maxAttempts) attempts"
        }
      } else if let text = text, let imageData = imageData, let imageUrl = saveImageToTempDirectory(imageData) {
        apiManager.generatePikaScenes(imageUrls: [imageUrl], promptText: text) { result in
          handleGenerationResult(result)
        }
      } else if let text = text {
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
      return fileURL
    } catch {
      print("❌ Error save videp: \(error.localizedDescription)")
      return nil
    }
  }

  private func handleGenerationResult(_ result: Result<String, Error>) {
    DispatchQueue.main.async {
      switch result {
      case .success(let generationId):
        print("✅ Generation start, ID: \(generationId)")
        lastGenerationId = generationId
        Task {
          await startCheckingStatus()
        }

      case .failure(let apiError):
        error = apiError.localizedDescription
        isGenerating = false
        print("🚨 Error generation: \(apiError.localizedDescription)")
      }
    }
  }

  private func startCheckingStatus() async {
    guard let generationId = lastGenerationId else {
      print("❌ Error: lastGenerationId not find")
      return
    }

    await MainActor.run {
      self.timer?.invalidate()
      self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
        print("🔄 [TIMER] Statuf for ID: \(generationId)...")
        Task {
          await self.checkGenerationStatus(for: generationId)
        }
      }
    }
  }

  @MainActor
  private func checkGenerationStatus(for generationId: String) async {
    do {
      if effectId != nil {
        let generations = try await HailuoManager.shared.fetchUserGenerations()

        if let generation = generations.first(where: { $0.id == Int(generationId) }) {
          print("📱 Checking generation: \(generation.id) with status: \(generation.status)")
          
          switch generation.status {
          case 3:
            if let videoUrl = generation.result {
              timer?.invalidate()
              if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
                GeneratedVideosManager.shared.updateVideo(
                  GeneratedVideo(
                    id: video.id,
                    generationId: generationId,
                    videoUrl: videoUrl,
                    promptText: video.promptText,
                    createdAt: video.createdAt,
                    status: .completed,
                    resultUrl: videoUrl
                  )
                )
                print("🎉 Video done: \(videoUrl)")
                NotificationManager.shared.sendVideoReadyNotification()
                dismiss()
                tabManager.selectedTab = 1
              }
            }
          case 4: 
            timer?.invalidate()
            if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
              GeneratedVideosManager.shared.deleteVideo(video)
            }
            showErrorAlert = true
            dismiss()
            tabManager.selectedTab = 1
          case 1, 2:
            print("⏳ Generation in progress...")
          default:
            print("❓ Unknown status: \(generation.status)")
          }
        } else {
          print("⚠️ Generation not found in list")
        }
      } else {
        let statusResponse = try await APIManager.shared.fetchGenerationStatus(generationId: generationId)
        switch statusResponse.status {
        case "processing", "queued", "pending":
          print("⏳ Generating...")
          
        case "completed", "finished":
          if let resultUrl = statusResponse.resultUrl {
            timer?.invalidate()
            if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
              GeneratedVideosManager.shared.updateVideo(
                GeneratedVideo(
                  id: video.id,
                  generationId: generationId,
                  videoUrl: resultUrl,
                  promptText: video.promptText,
                  createdAt: video.createdAt,
                  status: .completed,
                  resultUrl: resultUrl
                )
              )
              print("🎉 Video done: \(resultUrl)")
              NotificationManager.shared.sendVideoReadyNotification()
              dismiss()
              tabManager.selectedTab = 1
            }
          }
          
        case "error":
          timer?.invalidate()
          if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
            GeneratedVideosManager.shared.deleteVideo(video)
          }
          showErrorAlert = true
          dismiss()
          tabManager.selectedTab = 1

        default:
          print("❓ Unknown status: \(statusResponse.status)")
        }
      }
    } catch {
      print("❌ Error checking generation status: \(error)")
    }
  }
}
