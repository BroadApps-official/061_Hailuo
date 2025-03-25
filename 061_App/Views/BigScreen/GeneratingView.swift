import SwiftUI

struct GeneratingView: View {
  let imageData: Data?
  let text: String?
  let effectId: String?

  @StateObject private var apiManager = APIManager.shared
  @EnvironmentObject private var effectsViewModel: EffectsViewModel
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tabManager: TabManager
  @State private var timers: [String: Timer] = [:]
  @State private var showResultView = false
  @State private var generatedVideoUrl: String?
  @State private var isGenerating = true
  @State private var error: String?
  @State private var lastGenerationId: String?
  @State private var resultVideoUrl: String?
  @State private var resultPromptText: String?
  @State private var showErrorAlert = false
  @StateObject private var hailuoManager = HailuoManager.shared
  @StateObject private var generationManager = GenerationManager.shared

  init(imageData: Data? = nil, text: String? = nil, effectId: String? = nil) {
    self.imageData = imageData
    self.text = text
    self.effectId = effectId
  }

  var body: some View {
    NavigationStack {
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
      .background(Color.black.edgesIgnoringSafeArea(.all))
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
      .alert("Maximum Generations Reached", isPresented: $apiManager.showMaxGenerationsAlert) {
        Button("OK", role: .cancel) { }
      } message: {
        Text("You can only have \(generationManager.maxGenerations) active generations at a time. Please wait for one to complete before starting another.")
      }
      .alert("Maximum Generations Reached", isPresented: $hailuoManager.showMaxGenerationsAlert) {
        Button("OK", role: .cancel) { }
      } message: {
        Text("You can only have \(generationManager.maxGenerations) active generations at a time. Please wait for one to complete before starting another.")
      }
      .navigationDestination(isPresented: $showResultView) {
        if let videoUrl = generatedVideoUrl {
          ResultView(videoUrl: videoUrl, promptText: text)
        }
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
        if let existingVideo = GeneratedVideosManager.shared.videos.first(where: { $0.status == .generating && $0.effectId == Int(effectId) }) {
          print("✅ Found active generation: ID \(existingVideo.generationId)")
          lastGenerationId = existingVideo.generationId
          await startCheckingStatus(for: lastGenerationId!)
          return
        }
        
        let response = try await HailuoManager.shared.generateVideo(from: imageData, filterId: effectId)
        if response.error {
          error = response.messages.first ?? "Unknown error occurred"
          return
        }

        var lastGeneration: Generation?
        var attempts = 0
        let maxAttempts = 50
        
        while attempts < maxAttempts {
          let generations = try await HailuoManager.shared.fetchUserGenerations()
          lastGeneration = generations.last(where: { $0.status == 1 || $0.status == 2 || $0.status == 0  })

          if lastGeneration != nil {
            print("✅ Found active generation: ID \(lastGeneration!.id), status \(lastGeneration!.status)")
            break
          }
          
          print("⏳ Waiting for active generation... Attempt \(attempts + 1)")
          try await Task.sleep(nanoseconds: 2_000_000_000)
          attempts += 1
        }
        
        if let lastGeneration = lastGeneration {
          let generationId = String(lastGeneration.id)
          lastGenerationId = generationId

          let videoId = UUID().uuidString
          
          DispatchQueue.main.async {
            GeneratedVideosManager.shared.addVideo(
              GeneratedVideo(
                id: videoId,
                generationId: generationId,
                videoUrl: "",
                promptText: text,
                createdAt: Date(),
                status: .generating,
                effectId: Int(effectId)
              )
            )
          }

          await startCheckingStatus(for: generationId)
        } else {
          error = "Failed to start generation after \(maxAttempts) attempts"
        }
      } 
      else if let text = text, let imageData = imageData, let imageUrl = saveImageToTempDirectory(imageData) {
        apiManager.generatePikaScenes(imageUrls: [imageUrl], promptText: text) { result in
          handleGenerationResult(result)
        }
      }
      else if let text = text {
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

        let videoId = UUID().uuidString
        
        GeneratedVideosManager.shared.addVideo(
          GeneratedVideo(
            id: videoId,
            generationId: generationId,
            videoUrl: "",
            promptText: text,
            createdAt: Date(),
            status: .generating,
            effectId: effectId.flatMap { Int($0) }
          )
        )
        
        Task {
          await self.startCheckingStatus(for: generationId)
        }

      case .failure(let apiError):
        error = apiError.localizedDescription
        isGenerating = false
        print("🚨 Error generation: \(apiError.localizedDescription)")
      }
    }
  }

  private func startCheckingStatus(for generationId: String) async {
    await MainActor.run {
      timers[generationId]?.invalidate()

      let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
        print("🔄 [TIMER] Status for ID: \(generationId)...")
        Task {
          await self.checkGenerationStatus(for: generationId)
        }
      }
      timers[generationId] = timer
    }
  }

  @MainActor
  private func checkGenerationStatus(for generationId: String) async {
    do {
      if let effectId = effectId {
        let generations = try await HailuoManager.shared.fetchUserGenerations()
        
        if let generation = generations.first(where: { String($0.id) == generationId }) {
          if generation.status == 3 {
            // Генерация завершена
            generationManager.removeGeneration(generationId)
            timers[generationId]?.invalidate()
            timers.removeValue(forKey: generationId)
            
            if let videoUrl = generation.result {
              generatedVideoUrl = videoUrl
              resultVideoUrl = videoUrl
              resultPromptText = text
              showResultView = true
            }
          } else if generation.status == 4 {
            // Генерация завершилась с ошибкой
            generationManager.removeGeneration(generationId)
            timers[generationId]?.invalidate()
            timers.removeValue(forKey: generationId)
            error = "Generation failed"
          }
        }
      } else {
        let status = try await APIManager.shared.fetchGenerationStatus(generationId: generationId)
        print("📱 Checking generation: \(generationId) with status: \(status.status)")
        
        switch status.status {
        case "completed", "finished":
          if let videoUrl = status.resultUrl {
            timers[generationId]?.invalidate()
            timers.removeValue(forKey: generationId)
            
            if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId && $0.status == .generating }) {
              GeneratedVideosManager.shared.updateVideo(
                GeneratedVideo(
                  id: video.id,
                  generationId: generationId,
                  videoUrl: videoUrl,
                  promptText: video.promptText,
                  createdAt: video.createdAt,
                  status: .completed,
                  resultUrl: videoUrl,
                  effectId: nil
                )
              )
              print("🎉 Video done: \(videoUrl)")
              self.generatedVideoUrl = videoUrl
              self.isGenerating = false
              self.showResultView = true
            } else {
              print("⚠️ Error, no video found for ID: \(generationId)")
            }
          }
        case "failed":
          timers[generationId]?.invalidate()
          timers.removeValue(forKey: generationId)
          
          if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId && $0.status == .generating }) {
            GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .failed)
          }
          showErrorAlert = true
          dismiss()
          tabManager.selectedTab = 1
        default:
          print("⏳ Generation in progress...")
        }
      }
    } catch {
      print("❌ Error checking status: \(error.localizedDescription)")
      if isGenerating {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
          Task {
            await checkGenerationStatus(for: generationId)
          }
        }
      }
    }
  }
}
