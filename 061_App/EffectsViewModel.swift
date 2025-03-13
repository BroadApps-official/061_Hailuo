import Foundation
import Combine

@MainActor
class EffectsViewModel: ObservableObject {
    @Published var popularEffects: [Effect] = []
    @Published var allEffects: [Effect] = []
    @Published var isLoading = false  // ✅ Предотвращает повторную загрузку

    func fetchEffects() async {
        guard !isLoading else { return } // ✅ Если уже загружается, игнорируем
        isLoading = true

        guard let url = URL(string: "https://futuretechapps.shop/filters?appId=com.test.test&userId=250276BA-7773-4B6F-A69C-569BC7DD73EA") else { return }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer 0e9560af-ab3c-4480-8930-5b6c76b03eea", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FilterResponse.self, from: data)

            if !response.error {
                self.allEffects = response.data
                self.popularEffects = Array(response.data.prefix(2))
            }
        } catch {
            print("❌ Failed to fetch effects: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
