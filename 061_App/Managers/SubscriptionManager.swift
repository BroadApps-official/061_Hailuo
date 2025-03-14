import SwiftUI
import ApphudSDK

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var productsApphud: [ApphudProduct] = []
    @Published var isSubscribed: Bool = false

    private let paywallID = "main"

    private init() {
        Task {
            await loadPaywalls()
            await checkSubscriptionStatus()
        }
    }

    func loadPaywalls() async {
        await withCheckedContinuation { continuation in
            Apphud.paywallsDidLoadCallback { paywalls, error in
                guard let paywall = paywalls.first(where: { $0.identifier == self.paywallID }) else {
                    print("❌ Пэйволл с id \(self.paywallID) не найден")
                    continuation.resume()
                    return
                }

                Apphud.paywallShown(paywall)
                self.productsApphud = paywall.products

                print("✅ Найден пэйволл: \(paywall.identifier)")
                for product in self.productsApphud {
                    print("ℹ️ Продукт: \(product.productId)")
                }

                continuation.resume()
            }
        }
    }

    func checkSubscriptionStatus() async {
        let result = Apphud.hasPremiumAccess()
        DispatchQueue.main.async {
            self.isSubscribed = result
            print("✅ Подписка активна: \(result)")
        }
    }

    func startPurchase(product: ApphudProduct, completion: @escaping (Bool) -> Void) {
        Apphud.purchase(product) { [weak self] result in
            guard let self = self else { return }

            if let error = result.error {
                print("❌ Ошибка покупки: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let subscription = result.subscription, subscription.isActive() {
                completion(true)
                return
            }

            if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                completion(true)
                return
            }

            if Apphud.hasActiveSubscription() {
                completion(true)
                return
            }

            completion(false)
        }
    }

    func restorePurchases(completion: @escaping (Bool) -> Void) {
        Apphud.restorePurchases { subscriptions, _, error in
            if let error = error {
                print("❌ Ошибка восстановления: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let subscription = subscriptions?.first, subscription.isActive() || Apphud.hasActiveSubscription() {
                DispatchQueue.main.async {
                    self.isSubscribed = true
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }

    func getProductPrice(for productId: String) -> String {
        guard let product = productsApphud.first(where: { $0.skProduct?.productIdentifier == productId }) else {
            return "Loading..."
        }
        guard let skProduct = product.skProduct else {
            return "N/A"
        }
        let price = skProduct.price
        let priceString = "\(skProduct.priceLocale.currencySymbol ?? "$")\(price)"
        print("✅ Цена продукта \(productId): \(priceString)")
        return priceString
    }
}
