import Foundation
import SwiftUI
import Combine
import StoreKit
import ApphudSDK

@MainActor
final class APIManager: ObservableObject {
    static let shared = APIManager()

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

    var token: String = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"

    private let baseURL = "https://vewapnew.online/api/generate"

    private init() { }


    // MARK: - 📸 Pika Scenes (Фото + Промпт)
    func generatePikaScenes(images: [URL], promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/pikaScenes"
        var request = createMultipartRequest(url: endpoint)

        var bodyData = Data()
        let boundary = UUID().uuidString

        // 🔹 Добавляем параметры
        let params: [String: String] = [
            "mode": "precise",
            "promptText": promptText,
            "userId": userId,
            "appId": "com.test.test"
        ]

        for (key, value) in params {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }

        // 🔹 Добавляем фото
        for imageUrl in images {
            if let imageData = try? Data(contentsOf: imageUrl) {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"ingredients[]\"; filename=\"\(imageUrl.lastPathComponent)\"\r\n".data(using: .utf8)!)
                bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                bodyData.append(imageData)
                bodyData.append("\r\n".data(using: .utf8)!)
            }
        }

        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData

        sendRequest(request: request, completion: completion)
    }

    // MARK: - 📝 Text-to-Video (Промпт → Видео)
    func generateTextToVideo(promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/txt2video"
        var request = createMultipartRequest(url: endpoint)

        let boundary = UUID().uuidString
        var bodyData = Data()

        // 🔹 Добавляем параметры
        let params: [String: String] = [
            "promptText": promptText,
            "userId": userId,
            "appId": "com.test.test"
        ]

        for (key, value) in params {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }

        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData

        sendRequest(request: request, completion: completion)
    }

  // MARK: - ✅ Проверка статуса генерации
      func fetchGenerationStatus(generationId: String, completion: @escaping (Result<String, Error>) -> Void) {
          let url = "https://vewapnew.online/api/generationStatus?generationId=\(generationId)"
          var request = URLRequest(url: URL(string: url)!)
          request.httpMethod = "GET"
          request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
          request.setValue("application/json", forHTTPHeaderField: "Accept")

          URLSession.shared.dataTask(with: request) { data, _, error in
              if let error = error {
                  completion(.failure(error))
                  return
              }

              guard let data = data,
                    let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let dataDict = responseJSON["data"] as? [String: Any],
                    let status = dataDict["status"] as? String
              else {
                  completion(.failure(NSError(domain: "Invalid API Response", code: 0)))
                  return
              }

              if let errorMsg = dataDict["error"] as? String, !errorMsg.isEmpty {
                  completion(.failure(NSError(domain: errorMsg, code: 0)))
                  return
              }

              if let resultUrl = dataDict["resultUrl"] as? String {
                  completion(.success(resultUrl))
              } else {
                  completion(.success(status))
              }
          }.resume()
      }
  
    // MARK: - 🔄 Универсальные методы
    private func createMultipartRequest(url: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(UUID().uuidString)", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func sendRequest(request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = responseJSON["data"] as? [String: Any],
                  let generationId = dataDict["generationId"] as? String
            else {
                completion(.failure(NSError(domain: "Invalid API Response", code: 0)))
                return
            }

            completion(.success(generationId))
        }.resume()
    }
}

// MARK: - 🔹 Поддержка Identifiable для URL
extension URL: Identifiable {
    public var id: URL { self }
}

