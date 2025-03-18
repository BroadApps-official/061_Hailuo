import SwiftUI

struct OnboardingPage: View {
  let imageName: String
  let title: String
  let description: String
  let index: Int
  
  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        Image(imageName)
          .resizable()
          .scaledToFit()
        Spacer()
      }
      .overlay(
        LinearGradient(
          gradient: Gradient(colors: [
            Color.black.opacity(0),
            Color.black.opacity(0),
            Color.black.opacity(0.6),
            Color.black.opacity(1)
          ]),
          startPoint: .center,
          endPoint: .bottom
        )
      )
      .background(.black)
      .ignoresSafeArea()
      
      VStack(spacing: 0) {
        VStack(spacing: 8) {
          Text(title)
            .font(Typography.largeTitleEmphasized)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

          Text(description)
            .font(Typography.subheadline)
            .foregroundColor(ColorPalette.Label.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
      }
      .frame(maxHeight: .infinity, alignment: .bottom)
      .padding(.horizontal)
      .padding(.bottom, 50)
    }
    .background(.black)
  }
}

#Preview {
  OnboardingView(hasSeenOnboarding: .constant(false))
}

