import Foundation
import AVFoundation

class VideoCacheService {
  static let shared = VideoCacheService()
  private let cache = NSCache<NSString, NSData>()
  private let fileManager = FileManager.default
  private let cacheDirectory: URL
  
  private init() {
    let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    cacheDirectory = paths[0].appendingPathComponent("VideoCache")
    
    try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
  }
  
  func cacheVideo(from url: URL, completion: @escaping (URL?) -> Void) {
    let fileName = url.lastPathComponent
    let fileURL = cacheDirectory.appendingPathComponent(fileName)
    
    if fileManager.fileExists(atPath: fileURL.path) {
      completion(fileURL)
      return
    }
    
    URLSession.shared.downloadTask(with: url) { [weak self] downloadedURL, _, error in
      guard let downloadedURL = downloadedURL else {
        print("❌ Error downloading video: \(error?.localizedDescription ?? "Unknown error")")
        completion(nil)
        return
      }
      
      do {
        try self?.fileManager.moveItem(at: downloadedURL, to: fileURL)
        completion(fileURL)
      } catch {
        print("❌ Error caching video: \(error.localizedDescription)")
        completion(nil)
      }
    }.resume()
  }
  
  func getCachedVideoURL(for url: URL) -> URL? {
    let fileName = url.lastPathComponent
    let fileURL = cacheDirectory.appendingPathComponent(fileName)
    
    if fileManager.fileExists(atPath: fileURL.path) {
      return fileURL
    }
    
    return nil
  }
  
  func clearCache() {
    try? fileManager.removeItem(at: cacheDirectory)
    try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
  }
} 

class VideoSaver: NSObject {
    static let shared = VideoSaver()

    private var successHandler: (() -> Void)?
    private var errorHandler: (() -> Void)?

    var onSuccess: (() -> Void)? {
        get { successHandler }
        set { successHandler = newValue }
    }

    var onError: (() -> Void)? {
        get { errorHandler }
        set { errorHandler = newValue }
    }

    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("❌ Error saving video to gallery: \(error.localizedDescription)")
                self?.errorHandler?()
            } else {
                print("✅ Video saved successfully")
                self?.successHandler?()
            }
        }
    }
}
