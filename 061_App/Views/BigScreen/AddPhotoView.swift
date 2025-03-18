import SwiftUI
import PhotosUI
import AVFoundation

struct AddPhotoView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var selectedImageData: Data?
  @State private var showImagePicker = false
  @State private var showCamera = false
  @State private var showPermissionAlert = false
  @State private var permissionType: PermissionType = .camera
  @State private var showGeneratingView = false
  @StateObject private var effectsViewModel = EffectsViewModel()
  
  let effectId: String
  
  enum PermissionType {
    case camera
    case photoLibrary
  }
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        Capsule()
          .frame(width: 40, height: 4)
          .foregroundColor(Color.white.opacity(0.3))
          .padding(.top, 10)
        
        Text("Add photo")
          .font(.title2.bold())
          .foregroundColor(.white)
          .padding(.top, 4)
      }
      
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Bad examples")
            .font(.headline)
            .foregroundColor(.white)
          
          Text("Group photo, covered face, nudity, very large face, blurred face, very small face, hands not visible or covered.")
            .font(.footnote)
            .foregroundColor(.gray)
          
          Image("badExample")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
          
          Text("Good examples")
            .font(.headline)
            .foregroundColor(.white)
          
          Text("The photo was taken full-face (the man is standing straight), hands are visible.")
            .font(.footnote)
            .foregroundColor(.gray)
          
          Image("goodExample")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
      }
      .padding(.top, 10)
      
      Spacer()
      
      VStack(spacing: 8) {
        HStack(spacing: 12) {
          Button(action: {
            checkCameraPermission()
          }) {
            Text("Take a photo")
              .font(.headline)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.gray.opacity(0.3))
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          
          Button(action: {
            checkPhotoLibraryPermission()
          }) {
            Text("From the gallery")
              .font(.headline)
              .frame(maxWidth: .infinity)
              .padding()
              .background(GradientStyle.background)
              .foregroundColor(.black)
              .cornerRadius(12)
          }
        }
        .padding(.horizontal, 16)
        
        Text("Use images where the face and hands are visible for the best result.")
          .font(.footnote)
          .foregroundColor(.gray)
          .padding(.bottom, 12)
      }
    }
    .background(Color.black.opacity(0.8))
    .presentationDetents([.large])
    .presentationDragIndicator(.hidden)
    .sheet(isPresented: $showImagePicker) {
      ImagePicker(imageData: $selectedImageData, sourceType: .photoLibrary)
    }
    .sheet(isPresented: $showCamera) {
      ImagePicker(imageData: $selectedImageData, sourceType: .camera)
    }
    .alert("Permission required", isPresented: $showPermissionAlert) {
      Button("Settings") {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      switch permissionType {
      case .camera:
        Text("Please allow camera access in Settings to take photos.")
      case .photoLibrary:
        Text("Please allow photo library access in Settings to select photos.")
      }
    }
    .onChange(of: selectedImageData) { newValue in
      if newValue != nil {
        showGeneratingView = true
      }
    }
    .fullScreenCover(isPresented: $showGeneratingView) {
      if let imageData = selectedImageData {
        GeneratingView(imageData: imageData, effectId: effectId)
          .environmentObject(effectsViewModel)
      }
    }
  }
  
  private func checkCameraPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      showCamera = true
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          DispatchQueue.main.async {
            showCamera = true
          }
        }
      }
    default:
      permissionType = .camera
      showPermissionAlert = true
    }
  }
  
  private func checkPhotoLibraryPermission() {
    switch PHPhotoLibrary.authorizationStatus() {
    case .authorized, .limited:
      showImagePicker = true
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized || status == .limited {
          DispatchQueue.main.async {
            showImagePicker = true
          }
        }
      }
    default:
      permissionType = .photoLibrary
      showPermissionAlert = true
    }
  }
}

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var imageData: Data?
  let sourceType: UIImagePickerController.SourceType
  @Environment(\.dismiss) private var dismiss
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = sourceType
    picker.delegate = context.coordinator
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let image = info[.originalImage] as? UIImage,
         let imageData = image.jpegData(compressionQuality: 0.8) {
        parent.imageData = imageData
      }
      parent.dismiss()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}
