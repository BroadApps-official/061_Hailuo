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
    let status: String
    let error: String?
    let resultUrl: String?
}

enum APIError: Error {
  case invalidImageData
  case invalidResponse
  case invalidURL
  case serverError
}
