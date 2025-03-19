import Foundation
import Photos
import AVFoundation
import Combine
import SwiftUI

class ResultViewModel: ObservableObject {
  @Published var showSuccessAlert = false
  @Published var showErrorAlert = false
  @Published var showFilesSuccessAlert = false
  @Published var showFilesErrorAlert = false
  @Published var showDeleteAlert = false
  @Published var showAlert = false
  @Published var isLoading = true
  @Published var player: AVPlayer?
  @Published var playerItem: AVPlayerItem?
  
  let videoUrl: String
  let promptText: String?
  
  init(videoUrl: String, promptText: String?) {
    self.videoUrl = videoUrl
    self.promptText = promptText
    setupPlayer()
  }
  
  func setupPlayer() {
    guard let url = URL(string: videoUrl) else { return }
    if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
      setupPlayerWithURL(cachedURL)
      return
    }
    
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory
    let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
    
    URLSession.shared.downloadTask(with: url) { [weak self] downloadedURL, _, error in
      guard let downloadedURL = downloadedURL else {
        print("❌ Error loading video: \(error?.localizedDescription ?? "Unknown error")")
        return
      }
      
      do {
        if fileManager.fileExists(atPath: destinationURL.path) {
          try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: downloadedURL, to: destinationURL)
        
        DispatchQueue.main.async {
          self?.setupPlayerWithURL(destinationURL)
        }
      } catch {
        print("❌ Error saving video: \(error.localizedDescription)")
      }
    }.resume()
  }
  
  private func setupPlayerWithURL(_ url: URL) {
    let asset = AVAsset(url: url)
    let playerItem = AVPlayerItem(asset: asset)
    self.playerItem = playerItem
    let player = AVPlayer(playerItem: playerItem)
    self.player = player
    
    player.automaticallyWaitsToMinimizeStalling = true
    
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { [weak self] _ in
      player.seek(to: .zero)
      player.play()
    }
    
    Task {
      do {
        try await asset.load(.isPlayable)
        await MainActor.run {
          self.isLoading = false
          player.play()
        }
      } catch {
        print("Error loading video: \(error)")
        await MainActor.run {
          self.isLoading = false
        }
      }
    }
  }
  
  func cleanupPlayer() {
    player?.pause()
    player = nil
    playerItem = nil
    NotificationCenter.default.removeObserver(self)
  }
  
  func requestPhotoLibraryAccess() {
    let status = PHPhotoLibrary.authorizationStatus()
    
    if status == .authorized || status == .limited {
      saveToGallery()
    } else {
      PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
        DispatchQueue.main.async {
          if newStatus == .authorized || newStatus == .limited {
            self?.saveToGallery()
          } else {
            self?.showErrorAlert = true
          }
        }
      }
    }
  }
  
  func saveToGallery() {
    guard let url = URL(string: videoUrl) else { return }
    if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: cachedURL)
        request?.creationDate = Date()
      }) { [weak self] success, error in
        DispatchQueue.main.async {
          if success {
            self?.showSuccessAlert = true
          } else {
            self?.showErrorAlert = true
          }
        }
      }
      return
    }
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory
    let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
    
    URLSession.shared.downloadTask(with: url) { [weak self] downloadedURL, _, error in
      guard let downloadedURL = downloadedURL else {
        print("❌ Error loading video: \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
          self?.showErrorAlert = true
        }
        return
      }
      
      do {
        if fileManager.fileExists(atPath: destinationURL.path) {
          try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: downloadedURL, to: destinationURL)
        
        DispatchQueue.main.async {
          PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationURL)
            request?.creationDate = Date()
          }) { [weak self] success, error in
            DispatchQueue.main.async {
              if success {
                self?.showSuccessAlert = true
              } else {
                self?.showErrorAlert = true
              }
            }
          }
        }
      } catch {
        print("❌ Error saving video: \(error.localizedDescription)")
        DispatchQueue.main.async {
          self?.showErrorAlert = true
        }
      }
    }.resume()
  }
  
  func clearAlerts() {
    showSuccessAlert = false
    showErrorAlert = false
    showFilesSuccessAlert = false
    showFilesErrorAlert = false
    showDeleteAlert = false
    showAlert = false
  }
}
