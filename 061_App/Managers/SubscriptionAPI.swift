import Foundation

class SubscriptionAPI {
  static let shared = SubscriptionAPI()
  private let baseURL = "https://nextgenwebapps.shop/api/v1/user/setPaid"
  private let bearerToken = "f113066f-2ad6-43eb-b860-8683fde1042a"
  
  func setPaidPlan(userId: String, productId: Int, source: String = "com.test.test", completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard var urlComponents = URLComponents(string: baseURL) else {
      completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
      return
    }
    
    urlComponents.queryItems = [
      URLQueryItem(name: "userId", value: userId),
      URLQueryItem(name: "productId", value: "\(productId)"),
      URLQueryItem(name: "source", value: source)
    ]
    
    guard let url = urlComponents.url else {
      completion(.failure(NSError(domain: "Invalid Query Parameters", code: 0, userInfo: nil)))
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    
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
}
