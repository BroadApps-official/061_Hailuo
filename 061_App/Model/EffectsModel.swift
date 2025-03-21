import SwiftUI

struct Effect: Identifiable, Codable {
  let id: Int
  let title: String
  let preview: String
  let previewSmall: String
  
  enum CodingKeys: String, CodingKey {
    case id, title, preview
    case previewSmall = "preview_small"
  }
}

struct FilterResponse: Codable {
  let error: Bool
  let messages: [String]
  let data: [Effect]
}

struct VideoGenerationResponse: Codable {
  let error: Bool
  let messages: [String]
  let data: [String]
}

struct GenerationResponse: Decodable {
  let error: Bool
  let messages: [String]
  let data: [Generation]
}

struct Generation: Decodable {
  let id: Int
  let status: Int
  let prompt: String?
  let photo: String?
  let result: String?
}

struct GenerationStatusResponse: Codable {
  let error: Bool
  let messages: [String]
  let data: GenerationStatusData
}

struct GenerationStatusData: Codable {
  let status: String
  let error: String?
  let resultUrl: String?
  let progress: Int?
  let totalWeekGenerations: Int?
  let maxGenerations: Int?
}

enum APIError: Error {
  case invalidImageData
  case invalidResponse
  case invalidURL
  case serverError
  case maxGenerationsReached
  case generationInProgress
}

struct GeneratedVideo: Identifiable, Codable, Hashable {
  let id: String
  let generationId: String
  let videoUrl: String
  let promptText: String?
  let createdAt: Date
  var status: VideoStatus
  var resultUrl: String?
  let effectId: Int?
  
  enum VideoStatus: String, Codable {
    case generating
    case completed
    case failed
  }
}
