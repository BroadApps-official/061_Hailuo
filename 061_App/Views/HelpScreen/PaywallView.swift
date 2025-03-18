import SwiftUI
import StoreKit
import ApphudSDK

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPlan: ApphudProduct?
    @State private var isPurchasing = false
    @State private var showCloseButton = true

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                Image("paywallImage")
                    .resizable()
                    .scaledToFill()
                    .frame(height: UIScreen.main.bounds.height * 0.56)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.5)
                            ]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Group {
                            if showCloseButton {
                                HStack {
                                  Spacer()
                                    Button(action: { dismiss() }) {
                                        Image(systemName: "xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.trailing, 30)
                                    .padding(.bottom, UIScreen.main.bounds.height / 2 - 90)
                                }
                            }
                        }
                    )
                    .background(.black)
                    .edgesIgnoringSafeArea(.all)

              Text("Create creative videos")
                .font(.system(size: 28, weight: .bold))
                  .foregroundColor(.white)
                  .padding(.top, UIScreen.main.bounds.height * -0.24)

                VStack(alignment: .leading, spacing: 10) {
                    SubscriptionFeature(text: "Access to all effects")
                    SubscriptionFeature(text: "Unlimited generation")
                    SubscriptionFeature(text: "Access to all functions")
                }
                .padding(.horizontal, 24)
                .padding(.top, UIScreen.main.bounds.height * -0.2)

              VStack(spacing: 12) {
                  ForEach(subscriptionManager.productsApphud.sorted(by: { lhs, rhs in
                      (lhs.skProduct?.subscriptionPeriod?.unit == .year && rhs.skProduct?.subscriptionPeriod?.unit == .week)
                  }), id: \.productId) { product in
                      SubscriptionOptionView(product: product, selectedPlan: $selectedPlan)
                  }
              }
              .onReceive(subscriptionManager.$productsApphud) { products in
                  if selectedPlan == nil, let weeklyProduct = products.first(where: { $0.skProduct?.subscriptionPeriod?.unit == .week }) {
                      selectedPlan = weeklyProduct
                  }
              }
                .padding(.horizontal, 16)
                .padding(.top, -40)

                Button(action: purchaseSubscription) {
                    Text("Continue")
                    .font(Typography.bodyEmphasized)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(GradientStyle.background)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .disabled(isPurchasing || selectedPlan == nil)
                .padding(.top, 10)

                HStack {
                  Button("Privacy Policy") {
                      openURL("https://docs.google.com/document/d/11XBfYAuGvIj-tq7o22zMtqbmjH_Wp_ZZKU2ODwqwvDE/edit?usp=sharing")
                  }
                    Spacer()
                    Button("Restore Purhases", action: restorePurchases)
                    Spacer()
                  Button("Terms of Use") {
                      openURL("https://docs.google.com/document/d/1_aqT5H9GYmH1IDlyeTLvP0AUuOzHEhRiikDaaLY_G9A/edit?usp=sharing")
                  }

                }
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .task {
                  await subscriptionManager.loadPaywalls()
                }
            }
        }
    }

    private func purchaseSubscription() {
        guard let product = selectedPlan else { return }
        isPurchasing = true

        subscriptionManager.startPurchase(product: product) { success in
            isPurchasing = false
            if success { dismiss() }
        }
    }

    private func restorePurchases() {
        subscriptionManager.restorePurchases { success in
            if success { dismiss() }
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct SubscriptionFeature: View {
    let text: String
    var body: some View {
        HStack {
          Image("sparkles")
              .renderingMode(.template)
              .foregroundColor(ColorPalette.Accent.primary)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

struct SubscriptionOptionView: View {
    let product: ApphudProduct
    @Binding var selectedPlan: ApphudProduct?
    @ObservedObject var subscriptionManager = SubscriptionManager.shared

    private var isSelected: Bool {
        selectedPlan == product
    }

    private var isYearlySubscription: Bool {
        product.skProduct?.subscriptionPeriod?.unit == .year
    }

    var body: some View {
        Button(action: { selectedPlan = product }) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? ColorPalette.Accent.primary : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Just \(subscriptionManager.getProductPrice(for: product.productId)) / \(isYearlySubscription ? "Year" : "Week")")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Text("Auto renewable. Cancel anytime.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    ZStack {
                        if isSelected {
                            GradientStyle.background.opacity(0.2)
                        } else {
                            Color.white.opacity(0.05)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? ColorPalette.Accent.primary : Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)

                if isYearlySubscription {
                    Text("SAVE 40%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SubscriptionPlan: String, CaseIterable {
  case yearly, weekly

  var productId: String {
    switch self {
    case .yearly: return "yearly_59.99_nottrial"
    case .weekly: return "week_7.99_nottrial"
    }
  }
}


#Preview {
    PaywallView()
}
