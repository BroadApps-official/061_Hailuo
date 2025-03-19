import SwiftUI
import ApphudSDK
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
  static let shared = SubscriptionManager()
  
  @Published private(set) var hasActiveSubscription = false
  @Published private(set) var products: [ApphudProduct] = []
  @Published private(set) var isLoading = false
  @Published private(set) var error: String?
  
  @Published var productsApphud: [ApphudProduct] = []
  @Published var isSubscribed: Bool = false
  
  private let paywallID = "main"
  
  private var cancellables = Set<AnyCancellable>()
  
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
          print("❌ Paywall with id \(self.paywallID) not found")
          continuation.resume()
          return
        }
        
        Apphud.paywallShown(paywall)
        self.productsApphud = paywall.products
        
        print("✅ Found paywall: \(paywall.identifier)")
        for product in self.productsApphud {
          print("ℹ️ Product: \(product.productId)")
        }
        
        continuation.resume()
      }
    }
  }
  
  func checkSubscriptionStatus() async {
    let result = Apphud.hasPremiumAccess()
    DispatchQueue.main.async {
      self.isSubscribed = result
      print("✅ Subscribe: \(result)")
    }
  }
  
  func startPurchase(product: ApphudProduct, completion: @escaping (Bool) -> Void) {
    Apphud.purchase(product) { [weak self] result in
      guard let self = self else { return }
      
      if let error = result.error {
        print("❌ Error: \(error.localizedDescription)")
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
        print("❌ Error restore: \(error.localizedDescription)")
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
    print("✅ Price is \(productId): \(priceString)")
    return priceString
  }
}
