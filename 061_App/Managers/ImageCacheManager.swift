import SwiftUI
import CryptoKit

class ImageCacheManager {
  static let shared = ImageCacheManager()
  private let fileManager = FileManager.default
  private let cacheDirectory: URL
  
  init() {
    let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    cacheDirectory = urls[0].appendingPathComponent("ImageCache", isDirectory: true)
    if !fileManager.fileExists(atPath: cacheDirectory.path) {
      try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
  }
  
  func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
    let fileURL = cacheDirectory.appendingPathComponent(urlString.sha256 + ".jpg")
    if let cachedImage = loadFromDisk(fileURL: fileURL) {
      completion(cachedImage)
      return
    }
    
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }
    
    URLSession.shared.dataTask(with: url) { data, _, _ in
      if let data = data, let image = UIImage(data: data) {
        self.saveToDisk(image: image, fileURL: fileURL)
        DispatchQueue.main.async {
          completion(image)
        }
      } else {
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }.resume()
  }
  
  private func saveToDisk(image: UIImage, fileURL: URL) {
    if let data = image.jpegData(compressionQuality: 0.8) {
      try? data.write(to: fileURL)
    }
  }
  
  private func loadFromDisk(fileURL: URL) -> UIImage? {
    if let data = try? Data(contentsOf: fileURL) {
      return UIImage(data: data)
    }
    return nil
  }
}

extension String {
  var sha256: String {
    let hash = SHA256.hash(data: self.data(using: .utf8) ?? Data())
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
}

struct CachedAsyncImage: View {
  let url: String
  @State private var image: UIImage?
  
  var body: some View {
    Group {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        ProgressView()
          .onAppear {
            ImageCacheManager.shared.loadImage(from: url) { loadedImage in
              self.image = loadedImage
            }
          }
      }
    }
    .frame(width: 169, height: 240)
  }
}

struct CachedProjectsAsyncImage: View {
  let url: String
  @State private var image: UIImage?
  
  var body: some View {
    Group {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .clipShape(RoundedRectangle(cornerRadius: 20))
      } else {
        ProgressView()
          .onAppear {
            ImageCacheManager.shared.loadImage(from: url) { loadedImage in
              self.image = loadedImage
            }
          }
      }
    }
    .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 213)
    .cornerRadius(20)
  }
}

struct CachedAvatarAsyncImage: View {
  let url: String
  @State private var image: UIImage?
  
  var body: some View {
    Group {
      if let image = image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .clipShape(Circle())
      } else {
        ProgressView()
          .onAppear {
            ImageCacheManager.shared.loadImage(from: url) { loadedImage in
              self.image = loadedImage
            }
          }
      }
    }
    .frame(width: 100, height: 100)
  }
}
