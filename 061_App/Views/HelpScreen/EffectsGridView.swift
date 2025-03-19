import SwiftUI

struct EffectsGridView: View {
    let title: String
    let effects: [Effect]
    @Environment(\.dismiss) private var dismiss

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                  dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.title2)
                }

                Spacer()

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                ProBadgeButton()
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.black)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(effects, id: \ .id) { effect in
                        NavigationLink(destination: EffectDetailView(selectedEffect: effect, effects: effects)) {
                            EffectCell(effect: effect)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
