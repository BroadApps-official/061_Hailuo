import SwiftUI
import AVKit

struct EffectDetailView: View {
    let selectedEffect: Effect
    let effects: [Effect]
    @Environment(\.dismiss) private var dismiss
    @State private var isVideoLoaded = false
    @State private var showAddPhotoSheet = false

    var body: some View {
        VStack {
            if let url = URL(string: selectedEffect.preview) {
                VideoLoopPlayerWithLoading(url: url, isLoaded: $isVideoLoaded, effectId: selectedEffect.id)
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.8)
                    .scaleEffect(2)
                    .cornerRadius(12)
                    .clipped()
            }

            Button(action: {
                showAddPhotoSheet = true
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(GradientStyle.background)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            .sheet(isPresented: $showAddPhotoSheet) {
              AddPhotoView(effectId: selectedEffect.id.description) 
            }

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ColorPalette.Accent.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                Text(selectedEffect.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
