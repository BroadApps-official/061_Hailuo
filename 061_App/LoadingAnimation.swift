import SwiftUI

struct RotatingArcView: View {
  @State private var isAnimating = false
  var body: some View {
    Circle()
      .trim(from: 0.0, to: 0.25)
      .stroke(
        LinearGradient(
          gradient: Gradient(colors: [
            Color(red: 1, green: 0, blue: 0.133),
            Color(red: 1, green: 0, blue: 0.133),
            Color(red: 1, green: 0.4, blue: 0),
            Color(red: 1, green: 0.667, blue: 0)
          ]),
          startPoint: .leading,
          endPoint: .trailing
        ),
        style: StrokeStyle(lineWidth: 8, lineCap: .round)
      )
      .frame(width: 100, height: 100)
      .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
      .animation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                 value: isAnimating)
      .onAppear {
        isAnimating = true
      }
  }
}

#Preview {
  RotatingArcView()
}
