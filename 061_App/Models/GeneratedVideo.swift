import Foundation

struct GeneratedVideo: Codable, Identifiable {
    let id: String
    let generationId: String
    let videoUrl: String
    let promptText: String?
    let createdAt: Date
    var status: VideoStatus
    var resultUrl: String?
    
    enum VideoStatus: String, Codable {
        case generating
        case completed
        case failed
    }
}

class GeneratedVideosManager: ObservableObject {
    static let shared = GeneratedVideosManager()
    @Published private(set) var videos: [GeneratedVideo] = []
    private let userDefaults = UserDefaults.standard
    private let videosKey = "generatedVideos"
    
    private init() {
        loadVideos()
    }
    
    func addVideo(_ video: GeneratedVideo) {
        videos.append(video)
        saveVideos()
    }
    
    func updateVideo(_ video: GeneratedVideo) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index] = video
            saveVideos()
        }
    }
    
    func updateVideoStatus(generationId: String, status: GeneratedVideo.VideoStatus, resultUrl: String? = nil) {
        if let index = videos.firstIndex(where: { $0.generationId == generationId }) {
            var video = videos[index]
            video.status = status
            video.resultUrl = resultUrl
            videos[index] = video
            saveVideos()
        }
    }
    
    func deleteVideo(_ video: GeneratedVideo) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos.remove(at: index)
            saveVideos()
        }
    }
    
    func clearVideos() {
        videos.removeAll()
        saveVideos()
    }
    
    private func loadVideos() {
        if let data = userDefaults.data(forKey: videosKey),
           let decodedVideos = try? JSONDecoder().decode([GeneratedVideo].self, from: data) {
            videos = decodedVideos
        }
    }
    
    private func saveVideos() {
        if let encoded = try? JSONEncoder().encode(videos) {
            userDefaults.set(encoded, forKey: videosKey)
        }
    }
} 