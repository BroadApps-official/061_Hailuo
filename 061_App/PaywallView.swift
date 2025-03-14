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
                .font(Typography.title1Emphasized)
                    .foregroundColor(.white)
                    .padding(.top, -200)

                VStack(alignment: .leading, spacing: 10) {
                    SubscriptionFeature(text: "Access to all effects")
                    SubscriptionFeature(text: "Unlimited generation")
                    SubscriptionFeature(text: "Access to all functions")
                }
                .padding(.horizontal, 24)
                .padding(.top, -170)

                VStack(spacing: 12) {
                    ForEach(subscriptionManager.productsApphud, id: \.productId) { product in
                        SubscriptionOptionView(product: product, selectedPlan: $selectedPlan)
                    }
                }
                .frame(width: .infinity)
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
                .frame(width: .infinity)
                .padding(.horizontal, 16)
                .disabled(isPurchasing || selectedPlan == nil)

                HStack {
                    Button("Terms of Service") {
                        openURL("https://docs.google.com/document/d/1GswJfATC1Ce4idZ3BPxQPzbdGOERuLafMsnofj7EnX8/edit?usp=sharing")
                    }
                    Spacer()
                    Button("Restore", action: restorePurchases)
                    Spacer()
                    Button("Privacy Policy") {
                        openURL("https://docs.google.com/document/d/19JuZ3Pxyz3oPI0yPRrzqFeMDqmtDm2HaBBi42R2sKhE/edit?usp=sharing")
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
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
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
}

struct SubscriptionOptionView: View {
    let product: ApphudProduct
    @Binding var selectedPlan: ApphudProduct?

    var body: some View {
        Button(action: { selectedPlan = product }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(product.skProduct?.localizedTitle ?? "Unknown Plan")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("$\(product.skProduct?.price.stringValue ?? "0.00") per week")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                Spacer()
                if selectedPlan == product {
                    Text("SAVE 40%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.2)))
                }
                Text("$\(product.skProduct?.price.stringValue ?? "0.00")")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedPlan == product ? Color.purple : Color.gray.opacity(0.4), lineWidth: 2)
            )
        }
    }
}

#Preview {
    PaywallView()
}
