import SwiftUI
import AVKit
import Photos
import UniformTypeIdentifiers

struct ResultView: View {
    let videoUrl: String
    let promptText: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var showFilesSuccessAlert = false
    @State private var showFilesErrorAlert = false
    @State private var localVideoURL: URL?
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var showDocumentPicker = false
    @State private var showAlert = false
//    @EnvironmentObject var networkMonitor: NetworkMonitor

    private var menuButton: some View {
        Menu {
            Button(action: { shareVideo() }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button(action: { saveToFiles() }) {
                Label("Save to Files", systemImage: "folder")
            }
            Button(role: .destructive, action: { showDeleteAlert = true }) {
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
            if let player = player {
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
                .opacity(promptText != nil ? 1 : 0)

            ScrollView {
                Text(promptText ?? "")
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
            .opacity(promptText != nil ? 1 : 0)
        }
        .padding(.horizontal)
        .frame(height: 160)
    }

    private var saveButton: some View {
        Button(action: { requestPhotoLibraryAccess() }) {
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
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .alert("Video saved to gallery", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Error, video not saved to gallery", isPresented: $showErrorAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Try Again") {
                requestPhotoLibraryAccess()
            }
        } message: {
            Text("Something went wrong or the server is not responding. Try again or do it later.")
        }
        .alert("Video saved to Files", isPresented: $showFilesSuccessAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Error, video not saved to Files", isPresented: $showFilesErrorAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Try Again") {
                saveToFiles()
            }
        }
        .alert("Delete this video?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { deleteVideo() }
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("It will disappear from the history in the My Videos tab. You will not be able to restore it after deletion.")
        }
//        .onReceive(networkMonitor.$isConnected) { isConnected in
//            if !isConnected {
//                showAlert = true
//            }
//        }
        .alert("No Internet Connection",
               isPresented: $showAlert,
               actions: {
            Button("OK") {}
        },
               message: {
            Text("Please check your internet settings.")
        })
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoUrl) else { return }

        if let cachedURL = VideoCacheService.shared.getCachedVideoURL(for: url) {
            print("📱 Используем кэшированное видео")
            setupPlayerWithURL(cachedURL)
            return
        }

        print("📱 Кэшируем видео")
        VideoCacheService.shared.cacheVideo(from: url) { cachedURL in
            if let cachedURL = cachedURL {
                DispatchQueue.main.async {
                    self.setupPlayerWithURL(cachedURL)
                }
            } else {
                print("❌ Не удалось кэшировать видео")
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
        ) { _ in
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
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        playerItem = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    private func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .authorized || status == .limited {
            downloadAndSaveVideo()
        } else {
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        downloadAndSaveVideo()
                    } else {
                        showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func downloadAndSaveVideo() {
        guard let url = URL(string: videoUrl) else { return }
        
        if url.isFileURL {
            saveToGallery(url)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { downloadedURL, _, error in
            guard let downloadedURL = downloadedURL else {
                DispatchQueue.main.async {
                    showErrorAlert = true
                }
                return
            }
            
            let fileManager = FileManager.default
            let destination = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: downloadedURL, to: destination)
                
                DispatchQueue.main.async {
                    self.localVideoURL = destination
                    self.saveToGallery(destination)
                }
            } catch {
                DispatchQueue.main.async {
                    showErrorAlert = true
                }
            }
        }
        task.resume()
    }
    
    private func saveToGallery(_ localURL: URL) {
        UISaveVideoAtPathToSavedPhotosAlbum(localURL.path, nil, nil, nil)
        DispatchQueue.main.async {
            showSuccessAlert = true
        }
    }
    
    private func saveToFiles() {
        guard let url = URL(string: videoUrl) else { return }
        let source = localVideoURL ?? url
        
        if source.isFileURL {
            presentDocumentPicker(url: source)
        } else {
            downloadToLocal(remoteURL: source) { localURL in
                guard let localURL = localURL else {
                    DispatchQueue.main.async {
                        showFilesErrorAlert = true
                    }
                    return
                }
                self.localVideoURL = localURL
                self.presentDocumentPicker(url: localURL)
            }
        }
    }
    
    private func downloadToLocal(remoteURL: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: remoteURL) { tmpURL, _, error in
            if let error = error {
                print("❌ Error download file: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let tmpURL = tmpURL else {
                completion(nil)
                return
            }
            
            let fileManager = FileManager.default
            let destination = fileManager.temporaryDirectory.appendingPathComponent(remoteURL.lastPathComponent)
            
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: tmpURL, to: destination)
                completion(destination)
            } catch {
                print("❌ Error placing file: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func presentDocumentPicker(url: URL) {
        DispatchQueue.main.async {
            let docPicker = UIDocumentPickerViewController(forExporting: [url], asCopy: false)
            docPicker.delegate = DocumentPickerHandler.shared
            docPicker.modalPresentationStyle = .formSheet
            
            DocumentPickerHandler.shared.onDocumentPicked = { savedURL in
                DispatchQueue.main.async {
                    self.showFilesSuccessAlert = true
                }
            }
            
            DocumentPickerHandler.shared.onCancel = {
                print("❌ Cancel save")
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(docPicker, animated: true)
            }
        }
    }
    
    private func shareVideo() {
        guard let url = URL(string: videoUrl) else { return }
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        
        if url.isFileURL {
            presentShareSheet(with: url)
            return
        }
        
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
                    self.presentShareSheet(with: destinationURL)
                }
            } catch {
                print("❌ Error saving video: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func presentShareSheet(with url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
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
