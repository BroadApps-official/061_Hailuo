import SwiftUI

struct EffectsGridView: View {
  let title: String
  let effects: [Effect]

  let columns = [GridItem(.flexible()), GridItem(.flexible())]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(effects, id: \.id) { effect in
          NavigationLink(destination: EffectDetailView(selectedEffect: effect, effects: effects)) {
            EffectCell(effect: effect)
          }
        }
      }
      .padding()
    }
    .navigationTitle(title)
    .background(Color.black.edgesIgnoringSafeArea(.all))
  }
}
