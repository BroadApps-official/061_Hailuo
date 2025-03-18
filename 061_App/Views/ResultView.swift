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
        }
      }

      DocumentPickerHandler.shared.onCancel = {
        print("❌ Cancel save")
      }

      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        let pickerWindow = UIWindow(windowScene: windowScene)
        pickerWindow.rootViewController = UIViewController()
        pickerWindow.makeKeyAndVisible()

        self.shareWindow = pickerWindow

        pickerWindow.rootViewController?.present(docPicker, animated: true)

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
    if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
      presentShareSheet(with: cachedURL)
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
          if let shareableURL = getShareableFileURL(for: url) {
            presentShareSheet(with: shareableURL)
          } else {
            print("❌ Can't create copy video for share")
          }
        }
      } catch {
        print("❌ Error saving video: \(error.localizedDescription)")
      }
    }.resume()
  }

  private func presentShareSheet(with url: URL) {
    let activityVC = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )

    activityVC.completionWithItemsHandler = { _, _, _, _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.shareWindow?.isHidden = true
        self.shareWindow = nil
      }
    }

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
      let shareWindow = UIWindow(windowScene: windowScene)
      shareWindow.rootViewController = UIViewController()
      shareWindow.makeKeyAndVisible()

      self.shareWindow = shareWindow

      shareWindow.rootViewController?.present(activityVC, animated: true)
    } else {
      print("❌ Error: can't find active window")
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
      print("❌ Error copy file: \(error.localizedDescription)")
      return nil
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

