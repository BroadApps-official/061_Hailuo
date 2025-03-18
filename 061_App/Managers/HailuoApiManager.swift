import Foundation
import SwiftUI
import ApphudSDK
import Combine

@MainActor
final class HailuoManager: ObservableObject {
  static let shared = HailuoManager()

  private let baseURL = "https://futuretechapps.shop"
  private let appId = "com.test.test"
  private let token = "0e9560af-ab3c-4480-8930-5b6c76b03eea"

  @Published var userGenerations: [Generation] = []
  @Published var newGenerations: [Generation] = []
  @Published var isGenerating = false
  @Published var error: String?
  @AppStorage("apphudUserId") private var storedUserId: String?

  var userId: String {
    if let existingId = storedUserId {
      return existingId
    } else {
      let newUserId = Apphud.userID()
      storedUserId = newUserId
      return newUserId
    }
  }

  private init() {}

  func fetchEffects() async throws -> [Effect] {
    guard let url = URL(string: "\(baseURL)/filters?appId=\(appId)&userId=\(userId)") else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw APIError.invalidResponse
    }

    let decoder = JSONDecoder()
    let filterResponse = try decoder.decode(FilterResponse.self, from: data)

    if filterResponse.error {
      throw APIError.serverError
    }

    return filterResponse.data
  }

  private func fixImageOrientation(_ imageData: Data) -> Data? {
    guard let image = UIImage(data: imageData) else { return nil }

    if image.imageOrientation == .up {
      return imageData
    }

    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    image.draw(in: CGRect(origin: .zero, size: image.size))
    guard let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
    UIGraphicsEndImageContext()

    return normalizedImage.jpegData(compressionQuality: 0.8)
  }

  func generateVideo(from imageData: Data, filterId: String? = nil) async throws -> VideoGenerationResponse {
    guard let correctedImageData = fixImageOrientation(imageData) else {
      throw APIError.invalidImageData
    }

    let boundary = UUID().uuidString
    var request = URLRequest(url: URL(string: "\(baseURL)/generate")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    var bodyData = Data()

    let parameters: [String: String?] = [
      "appId": appId,
      "userId": userId,
      "filter_id": filterId
    ]

    for (key, value) in parameters {
      if let value = value {
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(value)\r\n".data(using: .utf8)!)
      }
    }

    bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
    bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
    bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    bodyData.append(correctedImageData)
    bodyData.append("\r\n".data(using: .utf8)!)
    bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = bodyData

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw APIError.invalidResponse
    }

    let decoder = JSONDecoder()
    let videoResponse = try decoder.decode(VideoGenerationResponse.self, from: data)
    return videoResponse
  }

  func fetchUserGenerations() async throws -> [Generation] {
    guard let url = URL(string: "\(baseURL)/generations?appId=\(appId)&userId=\(userId)") else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw APIError.invalidResponse
    }

    let decodedResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)

    if decodedResponse.error {
      throw APIError.serverError
    }

    DispatchQueue.main.async {
      self.userGenerations = decodedResponse.data
    }

    return decodedResponse.data
  }
}
