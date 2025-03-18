import SwiftUI
import PhotosUI

struct ImageTextToVideoView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var selectedImage: UIImage?
  @State private var selectedItem: PhotosPickerItem?
  @State private var text: String = ""
  @State private var showGeneratingView = false
  @FocusState private var isTextFieldFocused: Bool 
  
  var isButtonEnabled: Bool {
    return selectedImage != nil && !text.isEmpty
  }
  
  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(ColorPalette.Accent.primary)
        }
        Spacer()
        Text("Create")
          .font(Typography.headline)
          .foregroundColor(.white)
        Spacer()
      }
      .padding(.horizontal)
      
      if let image = selectedImage {
        ZStack(alignment: .topTrailing) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: 180)
            .cornerRadius(12)
            .clipped()
            .padding(.horizontal)
          
          Button(action: { selectedImage = nil }) {
            Image(systemName: "trash")
              .foregroundColor(.white.opacity(0.7))
              .padding(10)
              .background(Color.gray.opacity(0.6))
              .clipShape(Circle())
          }
          .padding(25)
          .padding(.top, 100)
        }
      } else {
        PhotosPicker(selection: $selectedItem, matching: .images) {
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.white.opacity(0.3), style: StrokeStyle(dash: [5]))
              .frame(height: 160)
            Text("+ Add image")
              .foregroundColor(.gray)
          }
        }
        .padding(.horizontal)
        .padding(.top)
        .onChange(of: selectedItem) { newItem in
          Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
              selectedImage = uiImage
            }
          }
        }
      }
      
      ZStack(alignment: .topLeading) {
        TextEditor(text: $text)
          .frame(height: !text.isEmpty ? 250 : 150)
          .padding(10)
          .foregroundColor(.white)
          .scrollContentBackground(.hidden)
          .background(Color.black)
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.white.opacity(0.3), lineWidth: 2)
          )
          .focused($isTextFieldFocused)
          .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button("Done") {
                isTextFieldFocused = false
              }
              .foregroundColor(.blue)
            }
          }
          .padding(.horizontal)
        
        if text.isEmpty {
          Text("Enter any query to create your video using AI")
            .foregroundColor(.gray)
            .padding(.leading, 25)
            .padding(.top, 18)
            .allowsHitTesting(false)
        }
        
        if !text.isEmpty {
          Button(action: { text = "" }) {
            Image(systemName: "trash")
              .foregroundColor(.white.opacity(0.7))
              .padding(10)
              .background(Color.gray.opacity(0.6))
              .clipShape(Circle())
          }
          .offset(x: UIScreen.main.bounds.width - 70, y: 215)
        }
      }
      .padding(.top, 10)
      
      Spacer()
      
      Button(action: { showGeneratingView = true }) {
        Text("Create")
          .font(.headline)
          .foregroundColor(isButtonEnabled ? .black : .gray)
          .frame(maxWidth: .infinity)
          .padding()
          .background(isButtonEnabled ? GradientStyle.background : GradientStyle.gray)
          .cornerRadius(12)
      }
      .padding(.horizontal)
      .disabled(!isButtonEnabled)
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .fullScreenCover(isPresented: $showGeneratingView) {
      GeneratingView(imageData: selectedImage?.pngData(), text: text)
    }
    .onTapGesture {
      hideKeyboard()
    }
  }
}

extension View {
  func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

#Preview {
  ImageTextToVideoView()
}
