import Foundation
import Combine

 final class HailuoManager: ObservableObject {
    static let shared = HailuoManager()

    private let baseURL = "https://futuretechapps.shop"
    private let appId = "com.test.test"
    private let userId = "250276BA-7773-4B6F-A69C-569BC7DD73EA"
    private let token = "0e9560af-ab3c-4480-8930-5b6c76b03eea"

     @Published var userGenerations: [Generation] = []
     @Published var newGenerations: [Generation] = []  // ✅ Новые элементы
     @Published var isGenerating = false
     @Published var error: String?

    private init() {}

    /// 📌 Загружает список эффектов
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

    /// 📌 Генерирует видео на сервере
    func generateVideo(from imageData: Data, filterId: String? = nil, model: String? = nil, prompt: String? = nil) async throws -> VideoGenerationResponse {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "\(baseURL)/generate")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        var bodyData = Data()

        // ✅ Добавляем параметры
        let parameters: [String: String?] = [
            "appId": appId,
            "userId": userId,
            "filter_id": filterId,
            "model": model,
            "prompt": prompt
        ]

        for (key, value) in parameters {
            if let value = value {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        // ✅ Добавляем изображение
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(VideoGenerationResponse.self, from: data)
    }

  func fetchUserGenerations() async throws -> [Generation] {
      guard let url = URL(string: "\(baseURL)/generations?appId=\(appId)&userId=\(userId)") else {
          throw APIError.invalidURL
      }

      var request = URLRequest(url: url)
      request.addValue("application/json", forHTTPHeaderField: "Accept")
      request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
          throw APIError.invalidResponse
      }

      let decodedResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)

      if decodedResponse.error {
          throw APIError.serverError
      }

      // ✅ Сохраняем данные
      DispatchQueue.main.async {
          self.userGenerations = decodedResponse.data
      }

      return decodedResponse.data // ✅ Теперь возвращаем массив
  }

}
