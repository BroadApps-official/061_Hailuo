import SwiftUI

struct TextToVideoView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var text: String = ""
  @State private var showGeneratingView = false
  
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
          .font(.headline)
          .foregroundColor(.white)
        
        Spacer()
      }
      .padding(.horizontal)

      ZStack(alignment: .topLeading) {
        TextEditor(text: $text)
          .frame(height: UIScreen.main.bounds.height / 2)
          .padding(10)
          .foregroundColor(.white)
          .scrollContentBackground(.hidden)
          .background(Color.black)
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.white.opacity(0.3), lineWidth: 2)
          )
          .padding(.horizontal)
        
        if text.isEmpty {
          Text("Enter any query to create your video using AI")
            .foregroundColor(.gray)
            .padding(.leading, 30)
            .padding(.top, 18)
            .allowsHitTesting(false)
        }

        if !text.isEmpty {
          Button(action: {
            text = ""
          }) {
            Image(systemName: "trash")
              .foregroundColor(.white.opacity(0.7))
              .padding(10)
              .background(Color.gray.opacity(0.6))
              .clipShape(Circle())
          }
          .offset(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height / 2 - 35)
        }
      }
      .padding(.top, 20)
      
      Spacer()

      Button(action: {
        showGeneratingView = true
      }) {
        Text("Create")
          .font(.headline)
          .foregroundColor(text.isEmpty ? ColorPalette.Label.quintuple : .black)
          .frame(maxWidth: .infinity)
          .padding()
          .background(text.isEmpty ? GradientStyle.gray : GradientStyle.background)
          .cornerRadius(12)
      }
      .padding(.horizontal)
      .disabled(text.isEmpty)
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .fullScreenCover(isPresented: $showGeneratingView) {
      GeneratingView(text: text)
    }
  }
}

#Preview {
    TextToVideoView()
}
