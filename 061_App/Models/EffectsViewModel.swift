import Foundation
import Combine

@MainActor
class EffectsViewModel: ObservableObject {
  @Published var popularEffects: [Effect] = []
  @Published var allEffects: [Effect] = []
  @Published var isLoading = false
  @Published var isGenerating = false
  @Published var generationError: String?
  
  private let hailuoManager = HailuoManager.shared
  
  func fetchEffects() async {
    guard !isLoading else { return }
    isLoading = true
    
    do {
      let effects = try await hailuoManager.fetchEffects()
      self.allEffects = effects
      self.popularEffects = Array(effects.prefix(2))
    } catch {
      print("❌ Failed to fetch effects: \(error.localizedDescription)")
    }
    
    isLoading = false
  }
  
  func generateVideo(from imageData: Data, filterId: String? = nil, model: String? = nil, prompt: String? = nil) async {
    guard !isGenerating else { return }
    isGenerating = true
    generationError = nil
    
    do {
      try await hailuoManager.generateVideo(from: imageData, filterId: filterId)
      print("✅ Video generation successful")
    } catch {
      generationError = error.localizedDescription
      print("❌ Video generation failed: \(error.localizedDescription)")
    }
    
    isGenerating = false
  }
}
