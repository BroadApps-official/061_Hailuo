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
  private var trackingTimers: [String: Timer] = [:]

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
        print("❌ Error loading image: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
    }

    bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = bodyData

    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      if let error = error {
        print("❌ Error \(error.localizedDescription)")
        completion(.failure(error))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
        return
      }

      guard let data = data else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          if let error = json["error"] as? String {
            print("❌ Error from server: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
            return
          }

          guard let data = json["data"] as? [String: Any],
                let generationId = data["generationId"] as? String else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
            return
          }

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
          completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
        }
      } catch {
        print("❌ Error parsing JSON: \(error)")
        completion(.failure(error))
      }
    }
    task.resume()
  }

  func generateTextToVideo(promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
    let parameters: [String: Any] = [
      "promptText": promptText,
      "userId": userId,
      "appId": "com.test.test"
    ]

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

    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      if let error = error {
        print("❌ Error: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
        return
      }

      guard let data = data else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          if let error = json["error"] as? String {
            print("❌ Error from server: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
            return
          }

          guard let data = json["data"] as? [String: Any],
                let generationId = data["generationId"] as? String else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
            return
          }

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
          completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
        }
      } catch {
        print("❌ Error parsing JSON: \(error)")
        completion(.failure(error))
      }
    }
    task.resume()
  }

  func generateImageTextToVideo(imageUrls: [URL], promptText: String, completion: @escaping (Result<String, Error>) -> Void) {
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
        print("❌ Error loading image: \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
    }

    bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = bodyData

    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      if let error = error {
        print("❌ Error \(error.localizedDescription)")
        completion(.failure(error))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
        return
      }

      guard let data = data else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          if let error = json["error"] as? String {
            print("❌ Error from server: \(error)")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
            return
          }

          guard let data = json["data"] as? [String: Any],
                let generationId = data["generationId"] as? String else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
            return
          }

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
          completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
        }
      } catch {
        print("❌ Error parsing JSON: \(error)")
        completion(.failure(error))
      }
    }
    task.resume()
  }

  private func startTrackingGeneration(generationId: String) {
    // Инвалидируем существующий таймер, если он есть
    trackingTimers[generationId]?.invalidate()
    
    // Создаем новый таймер для этой генерации
    let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
      guard let self = self else { return }

      Task {
        do {
          let response = try await self.fetchGenerationStatus(generationId: generationId)

          switch response.status {
          case "queued", "processing", "pending":
            print("⏳ Wait, generation in progress for ID: \(generationId)...")

          case "completed", "finished":
            if let videoUrl = response.resultUrl {
              // Инвалидируем таймер для этой генерации
              self.trackingTimers[generationId]?.invalidate()
              self.trackingTimers.removeValue(forKey: generationId)
              
              if let video = await GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId && $0.status == .generating }) {
                await GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .completed, resultUrl: videoUrl)
                print("🎉 Video done for ID \(generationId): \(videoUrl)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                  NotificationManager.shared.sendVideoReadyNotification()
                }
              }
            } else {
              print("⚠️ Error, no video URL for ID: \(generationId)")
            }

          case "failed", "error":
            // Инвалидируем таймер для этой генерации
            self.trackingTimers[generationId]?.invalidate()
            self.trackingTimers.removeValue(forKey: generationId)
            
            if let video = await GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId && $0.status == .generating }) {
              await GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .failed)
            }

          default:
            print("❓ Unknown status for ID \(generationId): \(response.status)")
          }
        } catch {
          // Инвалидируем таймер для этой генерации
          self.trackingTimers[generationId]?.invalidate()
          self.trackingTimers.removeValue(forKey: generationId)
          
          if let video = await GeneratedVideosManager.shared.videos.first(where: { $0.generationId == generationId && $0.status == .generating }) {
            await GeneratedVideosManager.shared.updateVideoStatus(id: video.id, status: .failed)
          }
          print("❌ Error checking status for ID \(generationId): \(error.localizedDescription)")
        }
      }
    }
    
    // Сохраняем таймер в словаре
    trackingTimers[generationId] = timer
  }

  deinit {
    // Очищаем все таймеры при деинициализации
    trackingTimers.values.forEach { $0.invalidate() }
    trackingTimers.removeAll()
  }

  func fetchGenerationStatus(generationId: String) async throws -> GenerationStatusData {
    let url = URL(string: "\(baseURL)/generationStatus?generationId=\(generationId)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw APIError.invalidResponse
    }

    do {
      let decodedResponse = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)

      if decodedResponse.data.status == "completed", let resultUrl = decodedResponse.data.resultUrl {
        lastResultUrl = resultUrl
      }

      return decodedResponse.data
    } catch {
      throw APIError.invalidResponse
    }
  }
}

class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
  }
}

extension URL: Identifiable {
  public var id: URL { self }
}


