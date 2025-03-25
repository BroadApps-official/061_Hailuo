import Foundation

@MainActor
class GeneratedVideosManager: ObservableObject {
  static let shared = GeneratedVideosManager()
  
  @Published private(set) var videos: [GeneratedVideo] = []
  @Published var favoriteVideos: [GeneratedVideo] = []
  private let videosKey = "savedVideos"
  
  private init() {
    loadVideos()
  }
  
  @MainActor
  func addVideo(_ video: GeneratedVideo) {
    if !videos.contains(where: { $0.generationId == video.generationId }) {
      videos.append(video)
      saveVideos()
    }
  }
  
  @MainActor
  func updateVideo(_ video: GeneratedVideo) {
    if let index = videos.firstIndex(where: { $0.id == video.id && $0.generationId == video.generationId }) {
      videos[index] = video
      saveVideos()
    }
  }
  
  @MainActor
  func updateVideoStatus(id: String, status: GeneratedVideo.VideoStatus, resultUrl: String? = nil) {
    if let index = videos.firstIndex(where: { $0.id == id }) {
      var updatedVideo = videos[index]
      updatedVideo.status = status
      if let resultUrl = resultUrl {
        updatedVideo.resultUrl = resultUrl
      }
      videos[index] = updatedVideo
      saveVideos()
      
      // Удаляем генерацию из счетчика, если статус completed или failed
      if status == .completed || status == .failed {
        GenerationManager.shared.removeGeneration(updatedVideo.generationId)
      }
    }
  }
  
  @MainActor
  func deleteVideo(_ video: GeneratedVideo) {
    videos.removeAll { $0.id == video.id }
    saveVideos()
  }
  
  @MainActor
  func clearVideos() {
    videos.removeAll()
    saveVideos()
  }
  
  func addToFavorites(_ video: GeneratedVideo) {
    if !favoriteVideos.contains(where: { $0.id == video.id }) {
      favoriteVideos.append(video)
    }
  }
  
  func removeFromFavorites(_ video: GeneratedVideo) {
    favoriteVideos.removeAll { $0.id == video.id }
  }
  
  func isFavorite(_ video: GeneratedVideo) -> Bool {
    return favoriteVideos.contains(where: { $0.id == video.id })
  }
  
  private func saveVideos() {
    if let encoded = try? JSONEncoder().encode(videos) {
      UserDefaults.standard.set(encoded, forKey: videosKey)
    }
  }
  
  private func loadVideos() {
    if let data = UserDefaults.standard.data(forKey: videosKey),
       let decoded = try? JSONDecoder().decode([GeneratedVideo].self, from: data) {
      videos = decoded
    }
  }
} 
