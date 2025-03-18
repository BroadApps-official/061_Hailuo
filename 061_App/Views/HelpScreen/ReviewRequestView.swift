import SwiftUI
import StoreKit

struct ReviewRequestView: View {
  @Environment(\.dismiss) var dismiss

  @AppStorage("videoGenerationCount") private var videoGenerationCount = 0
  @AppStorage("appLaunchCount") private var appLaunchCount = 0
  @AppStorage("hasRatedApp") private var hasRatedApp = false

  private let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id\(6743318475)?action=write-review")!

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Spacer()
        Button(action: { dismiss() }) {
          Image(systemName: "xmark")
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .foregroundColor(ColorPalette.Accent.primary)
        }
      }
      .padding(.trailing, 16)

      Spacer()

      Image("reviewIcon")
        .resizable()
        .scaledToFit()
        .frame(width: 300, height: 300)
        .padding(.top, 10)

      Text("**Do you like our app?**")
        .font(Typography.title3Emphasized)
        .multilineTextAlignment(.center)
        .foregroundColor(.white)

      Text("Please rate our app so we can improve it for you and make it even cooler")
        .font(Typography.footnote)
        .multilineTextAlignment(.center)
        .foregroundColor(ColorPalette.Label.secondary)
        .padding(.horizontal, 40)

      HStack(alignment: .center, spacing: 8) {
        Button(action: {
          dismiss()
        }) {
          Text("No")
            .font(Typography.bodyEmphasized)
            .frame(width: 159)
            .frame(height: 48)
            .background(ColorPalette.Accent.primaryAlpha)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.top, 20)

        Button(action: {
          openAppStoreReview()
        }) {
          Text("Yes")
            .font(Typography.bodyEmphasized)
            .frame(width: 159)
            .frame(height: 48)
            .background(GradientStyle.background)
            .foregroundColor(.black)
            .cornerRadius(8)
        }
        .padding(.top, 20)
      }
      Spacer()
    }
    .background(.black)
  }

  private func openAppStoreReview() {
    hasRatedApp = true
    if UIApplication.shared.canOpenURL(appStoreURL) {
      UIApplication.shared.open(appStoreURL)
    }
    dismiss()
  }
}

#Preview {
  ReviewRequestView()
}
