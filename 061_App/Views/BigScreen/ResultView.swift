import SwiftUI
import AVKit

struct ResultView: View {
  @StateObject private var viewModel: ResultViewModel
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var tabManager: TabManager
  @State private var shareWindow: UIWindow?

  init(videoUrl: String, promptText: String?) {
    _viewModel = StateObject(wrappedValue: ResultViewModel(videoUrl: videoUrl, promptText: promptText))
  }

  private func deleteVideo() {
    if let video = GeneratedVideosManager.shared.videos.first(where: { $0.resultUrl == viewModel.videoUrl }) {
      GeneratedVideosManager.shared.deleteVideo(video)
      dismiss()
      tabManager.selectedTab = 1
    }
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
    Button(action: {
      dismiss()
      tabManager.selectedTab = 1
    }) {
      Image(systemName: "chevron.left")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(ColorPalette.Accent.primary)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
  }

  private var videoPreview: some View {
    ZStack {
      if viewModel.isLoading {
        VStack(spacing: 16) {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(2.0)

          Text("Loading video...")
            .font(.headline)
            .foregroundColor(.white)

          Text("Please wait while we prepare your video")
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .frame(height: UIScreen.main.bounds.height / 1.8)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
      } else if let player = viewModel.player {
        VideoPlayer(player: player)
          .frame(height: UIScreen.main.bounds.height / 1.8)
          .scaleEffect(2)
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
    }
    .padding(.horizontal)
    .frame(height: 160)
    .opacity(viewModel.promptText != nil ? 1 : 0)
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
    .padding(.bottom, 40)
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
      .padding(.top, 20)
      videoPreview
      promptView
      saveButton
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .navigationBarBackButtonHidden(true)
    .onAppear {
      viewModel.setupPlayer()
      NotificationManager.shared.sendVideoReadyNotification()
    }
    .onDisappear {
      viewModel.cleanupPlayer()
      tabManager.selectedTab = 1
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
        Button("OK", role: .cancel) {
            DispatchQueue.main.async {
                viewModel.clearAlerts()
            }
        }
    }
    .alert("Video saved to Files", isPresented: $viewModel.showFilesSuccessAlert) {
        Button("OK") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.showFilesSuccessAlert = false
                self.shareWindow?.isHidden = true
                self.shareWindow = nil
            }
        }
    }
    .alert("Delete Video", isPresented: $viewModel.showDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        deleteVideo()
      }
    } message: {
      Text("Are you sure you want to delete this video?")
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
    if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
      presentDocumentPicker(url: cachedURL)
      return
    }

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
              self.shareWindow?.isHidden = true
              self.shareWindow = nil
          }
      }

      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        let pickerWindow = UIWindow(windowScene: windowScene)
        pickerWindow.rootViewController = UIViewController()
        pickerWindow.makeKeyAndVisible()

        self.shareWindow = pickerWindow

        DocumentPickerHandler.shared.onCancel = {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pickerWindow.isHidden = true
            self.shareWindow = nil
            self.viewModel.clearAlerts()
          }
        }

        pickerWindow.rootViewController?.present(docPicker, animated: true)
      }
    }
  }

  private func shareVideo() {
    guard let url = URL(string: viewModel.videoUrl) else { return }
    
    if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
      shareVideoFromURL(cachedURL)
      return
    }

    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory
    let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)

    viewModel.isLoading = true

    URLSession.shared.downloadTask(with: url) { downloadedURL, response, error in
      guard let downloadedURL = downloadedURL else {
        print("❌ Error loading video: \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
          self.viewModel.isLoading = false
        }
        return
      }

      do {
        if fileManager.fileExists(atPath: destinationURL.path) {
          try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: downloadedURL, to: destinationURL)
        
        VideoCacheService.shared.cacheVideo(from: destinationURL) { cachedURL in
          if cachedURL != nil {
            DispatchQueue.main.async {
              self.viewModel.isLoading = false
              self.shareVideoFromURL(destinationURL)
            }
          } else {
            DispatchQueue.main.async {
              self.viewModel.isLoading = false
            }
          }
        }
      } catch {
        print("❌ Error saving video: \(error.localizedDescription)")
        DispatchQueue.main.async {
          self.viewModel.isLoading = false
        }
      }
    }.resume()
  }

  private func shareVideoFromURL(_ url: URL) {
    guard FileManager.default.fileExists(atPath: url.path) else {
      print("❌ Video file does not exist at path: \(url.path)")
      return
    }

    let tempDirectory = FileManager.default.temporaryDirectory
    let shareURL = tempDirectory.appendingPathComponent("share_\(url.lastPathComponent)")
    
    do {
      if FileManager.default.fileExists(atPath: shareURL.path) {
        try FileManager.default.removeItem(at: shareURL)
      }
      try FileManager.default.copyItem(at: url, to: shareURL)
      
      DispatchQueue.main.async {
        let activityVC = UIActivityViewController(
          activityItems: [shareURL],
          applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
          let shareWindow = UIWindow(windowScene: windowScene)
          shareWindow.rootViewController = UIViewController()
          shareWindow.makeKeyAndVisible()
          
          self.shareWindow = shareWindow
          
          activityVC.completionWithItemsHandler = { _, _, _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              shareWindow.isHidden = true
              self.shareWindow = nil
            }
          }
          
          shareWindow.rootViewController?.present(activityVC, animated: true)
        }
      }
    } catch {
      print("❌ Error preparing video for share: \(error.localizedDescription)")
    }
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

