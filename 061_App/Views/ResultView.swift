import SwiftUI
import AVKit
import Photos
import UniformTypeIdentifiers

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
    }
    
    func setupPlayer() {
        guard let url = URL(string: videoUrl) else { return }

        if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
            setupPlayerWithURL(cachedURL)
            return
        }

        VideoCacheService.shared.cacheVideo(from: url) { cachedURL in
            if let cachedURL = cachedURL {
                DispatchQueue.main.async {
                    self.setupPlayerWithURL(cachedURL)
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
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
}

struct ResultView: View {
    @StateObject private var viewModel: ResultViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var shareWindow: UIWindow?
    
    init(videoUrl: String, promptText: String?) {
        _viewModel = StateObject(wrappedValue: ResultViewModel(videoUrl: videoUrl, promptText: promptText))
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: { shareVideo() }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button(action: { saveToFiles() }) {
                Label("Save to Files", systemImage: "folder")
            }
            Button(role: .destructive, action: { viewModel.showDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ColorPalette.Accent.primary)
        }
        .preferredColorScheme(.dark)
        .padding(.trailing, 18)
    }

    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ColorPalette.Accent.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }

    private var videoPreview: some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(height: UIScreen.main.bounds.height / 1.8)
                    .scaleEffect(1.3)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal)
                    .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .frame(height: UIScreen.main.bounds.height / 1.7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal)
            }
        }
    }

    private var promptView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Prompt")
                .font(Typography.headline)
                .foregroundColor(.white)
                .padding(.bottom, 8)
                .opacity(viewModel.promptText != nil ? 1 : 0)

            ScrollView {
                Text(viewModel.promptText ?? "")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .opacity(viewModel.promptText != nil ? 1 : 0)
        }
        .padding(.horizontal)
        .frame(height: 160)
    }

    private var saveButton: some View {
        Button(action: { viewModel.requestPhotoLibraryAccess() }) {
            Text("Save")
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(GradientStyle.background)
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                backButton

                Spacer()

                Text("Result")
                    .font(Typography.headline)
                    .foregroundColor(.white)

                Spacer()

                menuButton
            }
            .padding(.top, 8)
            videoPreview
            promptView
            saveButton
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.setupPlayer()
        }
        .onDisappear {
            viewModel.cleanupPlayer()
        }
        .alert("Video saved to gallery", isPresented: $viewModel.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Error, video not saved to gallery", isPresented: $viewModel.showErrorAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Try Again") {
                viewModel.requestPhotoLibraryAccess()
            }
        } message: {
            Text("Something went wrong or the server is not responding. Try again or do it later.")
        }
        .alert("Video saved to Files", isPresented: $viewModel.showFilesSuccessAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Error, video not saved to Files", isPresented: $viewModel.showFilesErrorAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Try Again") {
                saveToFiles()
            }
        }
        .alert("Delete this video?", isPresented: $viewModel.showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteVideo() }
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("It will disappear from the history in the My Videos tab. You will not be able to restore it after deletion.")
        }
        .alert("No Internet Connection",
               isPresented: $viewModel.showAlert,
               actions: {
            Button("OK") {}
        },
               message: {
            Text("Please check your internet settings.")
        })
    }
    
    private func saveToFiles() {
        guard let url = URL(string: viewModel.videoUrl) else { return }
        
        // Сначала проверяем кэш
        if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
            print("📱 Используем кэшированное видео для сохранения")
            presentDocumentPicker(url: cachedURL)
            return
        }
        
        // Если нет в кэше, загружаем
        print("📱 Загружаем видео для сохранения")
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        
        URLSession.shared.downloadTask(with: url) { downloadedURL, _, error in
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
                    self.presentDocumentPicker(url: destinationURL)
                }
            } catch {
                print("❌ Error saving video: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func presentDocumentPicker(url: URL) {
        DispatchQueue.main.async {
            let docPicker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
            docPicker.delegate = DocumentPickerHandler.shared
            docPicker.modalPresentationStyle = .formSheet
            
            DocumentPickerHandler.shared.onDocumentPicked = { savedURL in
                DispatchQueue.main.async {
                    self.viewModel.showFilesSuccessAlert = true
                }
            }
            
            DocumentPickerHandler.shared.onCancel = {
                print("❌ Cancel save")
            }
            
            // Создаем новое окно для презентации
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let pickerWindow = UIWindow(windowScene: windowScene)
                pickerWindow.rootViewController = UIViewController()
                pickerWindow.makeKeyAndVisible()
                
                // Сохраняем ссылку на окно
                self.shareWindow = pickerWindow
                
                // Показываем DocumentPicker
                pickerWindow.rootViewController?.present(docPicker, animated: true)
                
                // Добавляем обработчик закрытия
                DocumentPickerHandler.shared.onCancel = {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pickerWindow.isHidden = true
                        self.shareWindow = nil
                    }
                }
            }
        }
    }
    
  private func shareVideo() {
      guard let url = URL(string: viewModel.videoUrl) else { return }

      // Сначала проверяем кэш
      if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
          print("📱 Используем кэшированное видео для шаринга")
          presentShareSheet(with: cachedURL)
          return
      }

      // Если нет в кэше, загружаем
      print("📱 Загружаем видео для шаринга")
      let fileManager = FileManager.default
      let tempDirectory = fileManager.temporaryDirectory
      let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)

      URLSession.shared.downloadTask(with: url) { downloadedURL, _, error in
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
                if let shareableURL = getShareableFileURL(for: url) {
                    presentShareSheet(with: shareableURL)
                } else {
                    print("❌ Не удалось создать копию видео для шаринга")
                }
              }
          } catch {
              print("❌ Error saving video: \(error.localizedDescription)")
          }
      }.resume()
  }

  private func presentShareSheet(with url: URL) {
      print("📤 Открываем UIActivityViewController для URL: \(url)")
      
      let activityVC = UIActivityViewController(
          activityItems: [url],
          applicationActivities: nil
      )
      
      // Добавляем обработчик закрытия
      activityVC.completionWithItemsHandler = { _, _, _, _ in
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              self.shareWindow?.isHidden = true
              self.shareWindow = nil
          }
      }
      
      // Находим активное окно
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
         let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            
          // Создаем новый window для презентации
          let shareWindow = UIWindow(windowScene: windowScene)
          shareWindow.rootViewController = UIViewController()
          shareWindow.makeKeyAndVisible()
          
          // Сохраняем ссылку на окно
          self.shareWindow = shareWindow
          
          // Показываем UIActivityViewController
          shareWindow.rootViewController?.present(activityVC, animated: true)
      } else {
          print("❌ Ошибка: не удалось найти активное окно")
      }
  }

  func getShareableFileURL(for url: URL) -> URL? {
      let fileManager = FileManager.default
      let tempURL = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

      do {
          if fileManager.fileExists(atPath: tempURL.path) {
              try fileManager.removeItem(at: tempURL)
          }
          try fileManager.copyItem(at: url, to: tempURL)
          return tempURL
      } catch {
          print("❌ Ошибка копирования файла: \(error.localizedDescription)")
          return nil
      }
  }

    private func deleteVideo() {
        // TODO: Implement delete functionality
        dismiss()
    }
}

class DocumentPickerHandler: NSObject, UIDocumentPickerDelegate {
    static let shared = DocumentPickerHandler()
    
    var onDocumentPicked: ((URL) -> Void)?
    var onCancel: (() -> Void)?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let selectedFile = urls.first {
            onDocumentPicked?(selectedFile)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onCancel?()
    }
}

#Preview {
    ResultView(videoUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4", promptText: "hdh")
}


#Preview {
    ResultView(videoUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4", promptText: "hdh")
}


#Preview {
    ResultView(videoUrl: "https://media.pixverse.ai/pixverse/mp4/media/app/ea4f45e0-8dc0-40dc-b546-ec79ed5c537e_seed1736913394.mp4", promptText: "hdh")
}
