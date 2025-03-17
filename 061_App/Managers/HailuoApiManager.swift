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
       print("📱 Используем существующий userId: \(existingId)")
       return existingId
     } else {
       let newUserId = Apphud.userID()
       print("📱 Создаем новый userId: \(newUserId)")
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

    func generateVideo(from imageData: Data, filterId: String? = nil) async throws -> VideoGenerationResponse {
        print("📤 [HAILUO] Отправка запроса на генерацию видео с параметрами: filterId=\(filterId ?? "nil") \(userId)")
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
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [HAILUO] Неверный ответ от сервера")
            throw APIError.invalidResponse
        }

        print("📥 [HAILUO] HTTP статус: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ [HAILUO] Ошибка: статус ответа \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        let videoResponse = try decoder.decode(VideoGenerationResponse.self, from: data)
        print("✅ [HAILUO] Успешно получен ответ: \(videoResponse)")
        return videoResponse
    }

  func fetchUserGenerations() async throws -> [Generation] {
      print("📤 [HAILUO] Запрос на получение генераций пользователя")
      guard let url = URL(string: "\(baseURL)/generations?appId=\(appId)&userId=\(userId)") else {
          print("❌ [HAILUO] Неверный URL для запроса генераций")
          throw APIError.invalidURL
      }

      var request = URLRequest(url: url)
      request.addValue("application/json", forHTTPHeaderField: "Accept")
      request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
          print("❌ [HAILUO] Неверный ответ от сервера при получении генераций")
          throw APIError.invalidResponse
      }

      print("📥 [HAILUO] HTTP статус: \(httpResponse.statusCode)")

      guard httpResponse.statusCode == 200 else {
          print("❌ [HAILUO] Ошибка: статус ответа \(httpResponse.statusCode)")
          throw APIError.invalidResponse
      }

      let decodedResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)

      if decodedResponse.error {
          print("❌ [HAILUO] Ошибка от сервера: \(decodedResponse.error)")
          throw APIError.serverError
      }

      DispatchQueue.main.async {
          self.userGenerations = decodedResponse.data
      }

      print("✅ [HAILUO] Успешно получены генерации: \(decodedResponse.data)")
      return decodedResponse.data
  }

}
