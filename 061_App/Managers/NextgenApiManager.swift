import Foundation
import ApphudSDK
import SwiftUI

@MainActor
class AvatarAPI: ObservableObject {
  static let baseURL = "https://nextgenwebapps.shop/api/v1/avatar/add"
  static let loginURL = "https://nextgenwebapps.shop/api/v1/user/login"
  static let presetsURL = "https://nextgenwebapps.shop/api/v1/photo/styles"
  static let paidURL = "https://nextgenwebapps.shop/api/v1/user/setPaid"
  static let addAvatarGenURL = "https://nextgenwebapps.shop/api/v1/user/addAvatar"
  static let generateURL = "https://nextgenwebapps.shop/api/v1/photo/generate"
  static let godModeURL = "https://nextgenwebapps.shop/api/v1/photo/generate/godMode"
  static let text2photoURL = "https://nextgenwebapps.shop/api/v1/photo/generate/txt2img"

  static let bearerToken = "f113066f-2ad6-43eb-b860-8683fde1042a"
  static let shared = AvatarAPI()

  @AppStorage("apphudUserId") var storedUserId: String?
//  @Published var presets: [PresetCategory] = []
  @Published var gender: String = "f"
  @Published var isLoading = true
  @Published var isLoggedIn = false
//  @Published var avatars: [Avatar] = []

  var userId: String {
    if let existingId = storedUserId {
      return existingId
    } else {
      let newUserId = Apphud.userID()
      storedUserId = newUserId
      return newUserId
    }
  }

//  func addAvatar(_ avatar: Avatar) {
//    avatars.append(avatar)
//  }
//
//  func updateAvatar(withId id: String, newPreview: String?) {
//    if let index = avatars.firstIndex(where: { $0.id == Int(id) }) {
//      avatars[index].preview = newPreview
//      objectWillChange.send()
//    }
//  }
//
  func loginUser(completion: @escaping (Bool) -> Void) {
    guard let url = URL(string: AvatarAPI.loginURL) else { return }

    let params = [
      "userId": userId,
      "gender": gender,
      "source": "com.test.test"
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: params)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          print("❌ error log in \(error.localizedDescription)")
          completion(false)
          return
        }

        self.isLoggedIn = true
        print("✅ Log in, \(self.userId)")
        completion(true)
      }
    }.resume()
  }

//  func addAvatarGeneration(completion: @escaping (Result<AddAvatarResponse, Error>) -> Void) {
//
//    guard var urlComponents = URLComponents(string: AvatarAPI.addAvatarGenURL) else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    urlComponents.queryItems = [
//      URLQueryItem(name: "userId", value: userId),
//      URLQueryItem(name: "productId", value: "22"),
//      URLQueryItem(name: "source", value: "com.test.test")
//    ]
//
//    guard let url = urlComponents.url else {
//      completion(.failure(NSError(domain: "Invalid Query Parameters", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//      DispatchQueue.main.async {
//        if let error = error {
//          completion(.failure(error))
//          return
//        }
//
//        guard let data = data else {
//          completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
//          return
//        }
//
//        do {
//          let decodedResponse = try JSONDecoder().decode(AddAvatarResponse.self, from: data)
//          completion(.success(decodedResponse))
//        } catch {
//          completion(.failure(error))
//        }
//      }
//    }.resume()
//  }
//
  func setPaidPlan(productId: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard var urlComponents = URLComponents(string: AvatarAPI.paidURL) else {
      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
      return
    }

    urlComponents.queryItems = [
      URLQueryItem(name: "userId", value: userId),
      URLQueryItem(name: "productId", value: "\(productId)"),
      URLQueryItem(name: "source", value: "com.test.test")
    ]

    guard let url = urlComponents.url else {
      completion(.failure(NSError(domain: "Invalid Query Parameters", code: 0, userInfo: nil)))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NSError(domain: "Empty Response", code: 0, userInfo: nil)))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
          completion(.success(json))
        } else {
          completion(.failure(NSError(domain: "Invalid JSON Format", code: 0, userInfo: nil)))
        }
      } catch {
        completion(.failure(error))
      }
    }

    task.resume()
  }

//  static func uploadAvatar(userId: String, gender: String, photos: [UIImage], preview: UIImage?, completion: @escaping (Result<AvatarResponse, Error>) -> Void) {
//    guard let url = URL(string: baseURL) else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
//
//    let boundary = "Boundary-\(UUID().uuidString)"
//    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//    var body = Data()
//
//    body.append("--\(boundary)\r\n".data(using: .utf8)!)
//    body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
//    body.append("\(userId)\r\n".data(using: .utf8)!)
//
//    body.append("--\(boundary)\r\n".data(using: .utf8)!)
//    body.append("Content-Disposition: form-data; name=\"gender\"\r\n\r\n".data(using: .utf8)!)
//    body.append("\(gender)\r\n".data(using: .utf8)!)
//
//    for (index, image) in photos.enumerated() {
//      if let imageData = image.jpegData(compressionQuality: 0.8) {
//        body.append("--\(boundary)\r\n".data(using: .utf8)!)
//        body.append("Content-Disposition: form-data; name=\"photo[]\"; filename=\"photo\(index).jpg\"\r\n".data(using: .utf8)!)
//        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
//        body.append(imageData)
//        body.append("\r\n".data(using: .utf8)!)
//      }
//    }
//
//    if let previewImage = preview, let previewData = previewImage.jpegData(compressionQuality: 0.8) {
//      body.append("--\(boundary)\r\n".data(using: .utf8)!)
//      body.append("Content-Disposition: form-data; name=\"preview\"; filename=\"preview.jpg\"\r\n".data(using: .utf8)!)
//      body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
//      body.append(previewData)
//      body.append("\r\n".data(using: .utf8)!)
//    }
//
//    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//    request.httpBody = body
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//      if let error = error {
//        completion(.failure(error))
//        return
//      }
//
//      guard let data = data else {
//        completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
//        return
//      }
//
//      do {
//        let decodedResponse = try JSONDecoder().decode(AvatarResponse.self, from: data)
//        completion(.success(decodedResponse))
//      } catch {
//        completion(.failure(error))
//      }
//    }
//
//    task.resume()
//  }
//
//  func fetchAvatars(completion: @escaping (Result<[Avatar], Error>) -> Void) {
//    guard let url = URL(string: "https://nextgenwebapps.shop/api/v1/avatar/list?userId=\(userId)") else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "GET"
//    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//      DispatchQueue.main.async {
//        if let error = error {
//          print("❌\(error.localizedDescription)")
//          completion(.failure(error))
//          return
//        }
//        guard let data = data else {
//          print("❌")
//          completion(.failure(NSError(domain: "Empty response", code: 0, userInfo: nil)))
//          return
//        }
//
//        do {
//          let response = try JSONDecoder().decode(AvatarListResponse.self, from: data)
//          if response.error {
//            print("❌")
//            completion(.failure(NSError(domain: "Server error", code: 0, userInfo: nil)))
//          } else {
//            print("✅ ")
//            completion(.success(response.data))
//          }
//        } catch {
//          print("❌\(error.localizedDescription)")
//          completion(.failure(error))
//        }
//      }
//    }.resume()
//  }

//  func fetchPresets(gender: String, completion: @escaping (Result<[PresetCategory], Error>) -> Void) {
//    var queryItems: [URLQueryItem] = [
//      URLQueryItem(name: "userId", value: userId),
//      URLQueryItem(name: "lang", value: "en"),
//      URLQueryItem(name: "gender", value: gender),
//      URLQueryItem(name: "tag", value: "056")
//    ]
//
//    var urlComponents = URLComponents(string: AvatarAPI.presetsURL)!
//    urlComponents.queryItems = queryItems
//
//    guard let url = urlComponents.url else {
//      print("❌")
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "GET"
//    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//      DispatchQueue.main.async {
//        if let error = error {
//          print("❌\(error.localizedDescription)")
//          self.loadPresetsFromCacheIfAvailable()
//          completion(.failure(error))
//          return
//        }
//        guard let data = data else {
//          print("❌")
//          self.loadPresetsFromCacheIfAvailable()
//          completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
//          return
//        }
//
//        do {
//          let response = try JSONDecoder().decode(PresetsResponse.self, from: data)
//          if response.error {
//            print("❌")
//            self.loadPresetsFromCacheIfAvailable()
//            completion(.failure(NSError(domain: "Server error", code: 0, userInfo: nil)))
//          } else {
//            self.presets = response.data
//            self.isLoading = false
//            self.savePresetsToCache(response.data)
//            completion(.success(response.data))
//          }
//        } catch {
//          print("❌\(error.localizedDescription)")
//          self.loadPresetsFromCacheIfAvailable()
//          completion(.failure(error))
//        }
//      }
//    }.resume()
//  }
//

//  private func loadPresetsFromCacheIfAvailable() {
//    let context = CoreDataManager.shared.persistentContainer.viewContext
//    let fetchRequest: NSFetchRequest<CachedPreset> = CachedPreset.fetchRequest()
//
//    do {
//      let cachedPresets = try context.fetch(fetchRequest)
//      if !cachedPresets.isEmpty {
//        self.presets = cachedPresets.map { cachedPreset in
//          PresetCategory(
//            id: Int(cachedPreset.id),
//            title: cachedPreset.title ?? "Unknown",
//            preview: cachedPreset.preview ?? "",
//            isNew: cachedPreset.isNew,
//            templates: (cachedPreset.templates as? Set<CachedTemplate>)?.map { cachedTemplate in
//              PresetTemplate(
//                id: Int(cachedTemplate.id),
//                title: nil,
//                preview: cachedTemplate.preview ?? "",
//                gender: cachedTemplate.gender ?? "f",
//                isEnabled: cachedTemplate.isEnabled
//              )
//            } ?? []
//          )
//        }
//        self.isLoading = false
//        print("✅")
//      } else {
//        print("⚠️")
//      }
//    } catch {
//      print("❌\(error.localizedDescription)")
//    }
//  }
//
//  private func savePresetsToCache(_ presets: [PresetCategory]) {
//    let context = CoreDataManager.shared.context
//
//    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CachedPreset.fetchRequest()
//    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//    do {
//      try context.execute(deleteRequest)
//      try context.save()
//    } catch {
//      print("❌ \(error.localizedDescription)")
//    }
//
//    let group = DispatchGroup()
//
//    presets.forEach { preset in
//      let cachedPreset = CachedPreset(context: context)
//      cachedPreset.id = Int64(preset.id)
//      cachedPreset.title = preset.title
//      cachedPreset.preview = preset.preview
//
//      if let imageUrl = preset.preview,
//         let url = URL(string: imageUrl) {
//
//        group.enter()
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//          if let data = data, error == nil {
//            cachedPreset.imageData = data
//          }
//
//          group.leave()
//        }.resume()
//      }
//    }
//
//    group.notify(queue: .main) {
//      do {
//        try context.save()
//        print("✅ ")
//      } catch {
//        print("❌\(error.localizedDescription)")
//      }
//    }
//  }
//
//  private func loadPresetsFromCache() {
//    let context = CoreDataManager.shared.context
//    let fetchRequest: NSFetchRequest<CachedPreset> = CachedPreset.fetchRequest()
//
//    do {
//      let cachedPresets = try context.fetch(fetchRequest)
//      self.presets = cachedPresets.map { cachedPreset in
//        PresetCategory(
//          id: Int(cachedPreset.id),
//          title: cachedPreset.title ?? "Unknown",
//          preview: cachedPreset.preview,
//          isNew: cachedPreset.isNew,
//          templates: (cachedPreset.templates as? Set<CachedTemplate>)?.map { cachedTemplate in
//            PresetTemplate(
//              id: Int(cachedTemplate.id),
//              title: cachedTemplate.title,
//              preview: cachedTemplate.preview ?? "",
//              gender: cachedTemplate.gender ?? "f",
//              isEnabled: cachedTemplate.isEnabled
//            )
//          } ?? []
//        )
//      }
//      self.isLoading = false
//      print("✅")
//    } catch {
//      print("❌ Error loading presets from Core Data: \(error.localizedDescription)")
//    }
//  }
//
//  static func checkAvatarStatus(userId: String, id: Int, completion: @escaping (Result<AvatarStatusResponse, Error>) -> Void) {
//    let urlString = "https://nextgenwebapps.shop/api/v1/avatar/status?userId=\(userId)&generationId=\(id)"
//
//    guard let url = URL(string: urlString) else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "GET"
//    request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//      if let error = error {
//        completion(.failure(error))
//        return
//      }
//
//      guard let data = data else {
//        completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
//        return
//      }
//
//      do {
//        let jsonResponse = try JSONDecoder().decode([String: AvatarStatusResponse].self, from: data)
//        if let statusResponse = jsonResponse["data"] {
//          completion(.success(statusResponse))
//        } else {
//          completion(.failure(NSError(domain: "Invalid JSON format", code: 0, userInfo: nil)))
//        }
//      } catch {
//        completion(.failure(error))
//      }
//    }
//
//    task.resume()
//  }
//
//  func generatePhoto(userId: String, templateId: Int, avatarId: Int, completion: @escaping (Result<GenerationData, Error>) -> Void) {
//    guard var urlComponents = URLComponents(string: AvatarAPI.generateURL) else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    urlComponents.queryItems = [
//      URLQueryItem(name: "userId", value: userId),
//      URLQueryItem(name: "templateId", value: "\(templateId)"),
//      URLQueryItem(name: "avatarId", value: "\(avatarId)")
//    ]
//
//    guard let url = urlComponents.url else {
//      completion(.failure(NSError(domain: "Invalid Query Parameters", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//      if let error = error {
//        completion(.failure(error))
//        return
//      }
//
//      guard let data = data else {
//        completion(.failure(NSError(domain: "Empty Response", code: 0, userInfo: nil)))
//        return
//      }
//
//      do {
//        let decodedResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)
//
//        if let generationData = decodedResponse.data {
//          completion(.success(generationData))
//        } else {
//          completion(.failure(NSError(domain: "Invalid JSON Format", code: 0, userInfo: nil)))
//        }
//      } catch {
//        completion(.failure(error))
//      }
//    }
//
//    task.resume()
//  }
//
//  func generateInGodMode(userId: String, avatarId: Int, prompt: String, completion: @escaping (Result<GenerationData, Error>) -> Void) {
//    guard var urlComponents = URLComponents(string: AvatarAPI.godModeURL) else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    urlComponents.queryItems = [
//      URLQueryItem(name: "userId", value: userId),
//      URLQueryItem(name: "avatarId", value: "\(avatarId)"),
//      URLQueryItem(name: "prompt", value: prompt)
//    ]
//
//    guard let url = urlComponents.url else {
//      completion(.failure(NSError(domain: "Invalid Query Parameters", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//      if let error = error {
//        completion(.failure(error))
//        return
//      }
//
//      guard let data = data else {
//        completion(.failure(NSError(domain: "Empty Response", code: 0, userInfo: nil)))
//        return
//      }
//
//      do {
//        let decodedResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)
//
//        if let generationData = decodedResponse.data {
//          completion(.success(generationData))
//        } else {
//          completion(.failure(NSError(domain: "Invalid JSON Format", code: 0, userInfo: nil)))
//        }
//      } catch {
//        completion(.failure(error))
//      }
//    }
//
//    task.resume()
//  }
//
//  func generateTextToImage(userId: String, prompt: String, completion: @escaping (Result<GenerationData, Error>) -> Void) {
//    guard var urlComponents = URLComponents(string: AvatarAPI.text2photoURL) else {
//      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//      return
//    }
//
//    urlComponents.queryItems = [
//      URLQueryItem(name: "userId", value: userId),
//      URLQueryItem(name: "prompt", value: prompt)
//    ]
//
//    guard let url = urlComponents.url else {
//      completion(.failure(NSError(domain: "Invalid Query Parameters", code: 0, userInfo: nil)))
//      return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//      if let error = error {
//        completion(.failure(error))
//        return
//      }
//
//      guard let data = data else {
//        completion(.failure(NSError(domain: "Empty Response", code: 0, userInfo: nil)))
//        return
//      }
//
//      do {
//        let decodedResponse = try JSONDecoder().decode(GenerationResponse.self, from: data)
//
//        if let generationData = decodedResponse.data {
//          completion(.success(generationData))
//        } else {
//          completion(.failure(NSError(domain: "Invalid JSON Format", code: 0, userInfo: nil)))
//        }
//      } catch {
//        completion(.failure(error))
//      }
//    }
//
//    task.resume()
//  }
}
