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

    private let baseURL = "https://vewapnew.online/api/generate"
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        let delegate = InsecureURLSessionDelegate()
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    // MARK: - 📸 Pika Scenes (Фото + Промпт)
  func generatePikaScenes(imageUrls: [URL], promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
      let endpoint = "\(baseURL)/pikaScenes"
      var request = createMultipartRequest(url: endpoint)

      var bodyData = Data()
      let boundary = UUID().uuidString

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

      sendRequest(request: request, completion: completion)
  }


    // MARK: - 📝 Text-to-Video (Промпт → Видео)
    func generateTextToVideo(promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
        let parameters: [String: Any] = [
            "promptText": promptText,
            "userId": userId
        ]
        
        print("📱 Отправляем запрос с параметрами: \(parameters)")
        
        let url = URL(string: "\(baseURL)/generate")!
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
            self?.fetchGenerationStatus(generationId: generationId) { result in
                switch result {
                case .success(let status):
                    if status == "completed" {
                        timer.invalidate()
                        GeneratedVideosManager.shared.updateVideoStatus(
                            generationId: generationId,
                            status: .completed,
                            resultUrl: self?.lastResultUrl
                        )
                    } else if status == "failed" {
                        timer.invalidate()
                        GeneratedVideosManager.shared.updateVideoStatus(
                            generationId: generationId,
                            status: .failed
                        )
                    }
                case .failure:
                    timer.invalidate()
                    GeneratedVideosManager.shared.updateVideoStatus(
                        generationId: generationId,
                        status: .failed
                    )
                }
            }
        }
    }
    
    func fetchGenerationStatus(generationId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/status/\(generationId)")!
    var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("📱 Проверяем статус генерации: \(generationId)")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Ошибка запроса статуса: \(error.localizedDescription)")
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
            
            print("📱 Получен JSON статуса: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📱 Структура JSON статуса: \(json)")
                    
                    if let error = json["error"] as? String {
                        print("❌ Ошибка от сервера: \(error)")
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
                        return
                    }
                    
                    guard let data = json["data"] as? [String: Any],
                          let status = data["status"] as? String else {
                        print("❌ Отсутствует data или status в ответе")
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                        return
                    }
                    
                    if status == "completed", let resultUrl = data["resultUrl"] as? String {
                        self?.lastResultUrl = resultUrl
                        print("✅ Генерация завершена, URL: \(resultUrl)")
                    }
                    
                    completion(.success(status))
                } else {
                    print("❌ Не удалось распарсить JSON статуса")
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                }
            } catch {
                print("❌ Ошибка парсинга JSON статуса: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
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
        session.dataTask(with: request) { data, response, error in
      if let error = error {
                print("❌ Ошибка запроса: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
      
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP статус: \(httpResponse.statusCode)")
            }

            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Полученный JSON: \(jsonString)")
                }
            }

            guard let data = data,
                  let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Не удалось распарсить JSON")
                completion(.failure(NSError(domain: "Invalid JSON Format", code: 0)))
        return
      }
      
            print("🔍 Структура ответа: \(responseJSON)")

            if let error = responseJSON["error"] as? Bool, error {
                if let messages = responseJSON["messages"] as? [String], let firstMessage = messages.first {
                    print("❌ Ошибка от сервера: \(firstMessage)")
                    completion(.failure(NSError(domain: firstMessage, code: 0)))
                    return
                }
            }

            guard let dataDict = responseJSON["data"] as? [String: Any] else {
                print("❌ Отсутствует поле 'data' в ответе")
                completion(.failure(NSError(domain: "Missing 'data' field", code: 0)))
                return
            }

            guard let generationId = dataDict["generationId"] as? String else {
                print("❌ Отсутствует поле 'generationId' в data")
                completion(.failure(NSError(domain: "Missing 'generationId' field", code: 0)))
                return
            }

            print("✅ Успешно получен generationId: \(generationId)")
            completion(.success(generationId))
        }.resume()
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

