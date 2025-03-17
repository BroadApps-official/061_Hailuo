import Foundation
import SwiftUI
import Combine
import StoreKit
import ApphudSDK

@MainActor
final class APIManager: ObservableObject {
  static let shared = APIManager()

  @AppStorage("apphudUserId") private var storedUserId: String?
  private var lastResultUrl: String?
  
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
  
  var token: String = "rE176kzVVqjtWeGToppo4lRcbz3HRLoBrZREEvgQ8fKdWuxySCw6tv52BdLKBkZTOHWda5ISwLUVTyRoZEF0A33Xpk63lF9wTCtDxOs8XK3YArAiqIXVb7ZS4IK61TYPQMu5WqzFWwXtZc1jo8w"

  private let baseURL = "https://vewapnew.online/api"
  private let session: URLSession

  private init() {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 300
    let delegate = InsecureURLSessionDelegate()
    session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
  }

  @MainActor
  private func safeFetchGenerationStatus(generationId: String) async -> Result<GenerationStatusData, Error> {
      do {
          let response = try await fetchGenerationStatus(generationId: generationId)
          return .success(response)
      } catch {
          return .failure(error)
      }
  }

  // MARK: - 📸 Pika Scenes (Фото + Промпт)
  func generatePikaScenes(imageUrls: [URL], promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
    let boundary = UUID().uuidString
    let endpoint = "\(baseURL)/generate/pikaScenes"
    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    var bodyData = Data()

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

    for (index, imageUrl) in imageUrls.enumerated() {
      do {
        let imageData = try Data(contentsOf: imageUrl)
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"ingredients[]\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
      } catch {
        print("❌ Ошибка загрузки изображения: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
    }

    bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = bodyData

    print("📡 Отправляем Pika Scenes запрос на \(endpoint)")

    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        if let error = error {
        print("❌ Ошибка запроса: \(error.localizedDescription)")
        completion(.failure(error))
          return
        }
        
      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
        return
      }

      print("📡 HTTP статус: \(httpResponse.statusCode)")

      guard let data = data else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      print("📡 Получен JSON: \(String(data: data, encoding: .utf8) ?? "nil")")

      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          print("📡 Структура JSON: \(json)")

          if let error = json["error"] as? String {
            print("❌ Ошибка от сервера: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
      return
    }
    
          guard let data = json["data"] as? [String: Any],
                let generationId = data["generationId"] as? String else {
            print("❌ Отсутствует data или generationId в ответе")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
      return
    }
    
          print("✅ Успешно получен generationId: \(generationId)")

          let video = GeneratedVideo(
            id: UUID().uuidString,
            generationId: generationId,
            videoUrl: "",
            promptText: promptText,
            createdAt: Date(),
            status: .generating
          )
          GeneratedVideosManager.shared.addVideo(video)

          self?.startTrackingGeneration(generationId: generationId)

          completion(.success(generationId))
        } else {
          print("❌ Не удалось распарсить JSON")
          completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
        }
      } catch {
        print("❌ Ошибка парсинга JSON: \(error)")
        completion(.failure(error))
      }
    }
    task.resume()
  }


  // MARK: - 📝 Text-to-Video (Промпт → Видео)
  func generateTextToVideo(promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
    let parameters: [String: Any] = [
        "promptText": promptText,
        "userId": userId,
        "appId": "com.test.test"
    ]

    print("📱 Отправляем запрос с параметрами: \(parameters)")

    let url = URL(string: "\(baseURL)/generate/txt2video")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    } catch {
      completion(.failure(error))
      return
    }

    print("📱 Отправляем запрос на URL: \(url)")
    print("📱 Заголовки: \(request.allHTTPHeaderFields ?? [:])")

    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      if let error = error {
        print("❌ Ошибка запроса: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
        return
      }

      print("📱 HTTP статус: \(httpResponse.statusCode)")
      
      guard let data = data else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      print("📱 Получен JSON: \(String(data: data, encoding: .utf8) ?? "nil")")

      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          print("📱 Структура JSON: \(json)")

          if let error = json["error"] as? String {
            print("❌ Ошибка от сервера: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
            return
          }

          guard let data = json["data"] as? [String: Any],
                let generationId = data["generationId"] as? String else {
            print("❌ Отсутствует data или generationId в ответе")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
            return
          }

          print("✅ Успешно получен generationId: \(generationId)")

          let video = GeneratedVideo(
            id: UUID().uuidString,
            generationId: generationId,
            videoUrl: "",
            promptText: promptText,
            createdAt: Date(),
            status: .generating
          )
          GeneratedVideosManager.shared.addVideo(video)

          self?.startTrackingGeneration(generationId: generationId)

          completion(.success(generationId))
        } else {
          print("❌ Не удалось распарсить JSON")
          completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
        }
      } catch {
        print("❌ Ошибка парсинга JSON: \(error)")
        completion(.failure(error))
      }
    }
    task.resume()
  }
  
  private func startTrackingGeneration(generationId: String) {
      let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
          guard let self = self else { return }

          Task {
              do {
                  let response = try await self.fetchGenerationStatus(generationId: generationId)

                  switch response.status {
                  case "queued", "processing", "pending":
                      print("⏳ Генерация еще идет, ждем...")

                  case "completed":
                      if let videoUrl = response.resultUrl {
                          timer.invalidate()
                          if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
                              GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .completed, resultUrl: videoUrl)
                              print("🎉 Видео сгенерировано: \(videoUrl)")
                          }
                      } else {
                          print("⚠️ Ошибка: статус 'completed', но URL видео отсутствует!")
                      }

                  case "error":
                      timer.invalidate()
                      if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
                          GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .failed)
                      }
                      print("🚨 Ошибка: генерация не удалась.")

                  default:
                      print("❓ Неизвестный статус: \(response.status)")
                  }
              } catch {
                  timer.invalidate()
                  if let video = GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId }) {
                      GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .failed)
                  }
                  print("❌ Ошибка запроса статуса: \(error.localizedDescription)")
              }
          }
      }
  }

  func fetchGenerationStatus(generationId: String) async throws -> GenerationStatusData {
      let url = URL(string: "\(baseURL)/generationStatus?generationId=\(generationId)")!
      var request = URLRequest(url: url)
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

      print("📱 Проверяем статус Pika генерации: \(generationId)")

      // 📡 Асинхронный запрос
      let (data, response) = try await URLSession.shared.data(for: request)

      // 📡 Проверяем HTTP статус-код
      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
          throw APIError.invalidResponse
      }

      print("📱 HTTP статус: \(httpResponse.statusCode)")
      print("📱 Получен JSON статуса: \(String(data: data, encoding: .utf8) ?? "nil")")

      // 📡 Декодируем JSON в модель
      do {
        let decodedResponse = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)

        if decodedResponse.data.status == "completed", let resultUrl = decodedResponse.data.resultUrl {
              lastResultUrl = resultUrl
              print("✅ Генерация завершена, URL: \(resultUrl)")
          }

        return decodedResponse.data
      } catch {
          print("❌ Ошибка парсинга JSON статуса: \(error)")
          throw APIError.invalidResponse
      }
  }
}

// MARK: - 🔹 Поддержка небезопасных соединений
class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
  }
}

// MARK: - 🔹 Поддержка Identifiable для URL
extension URL: Identifiable {
  public var id: URL { self }
}

