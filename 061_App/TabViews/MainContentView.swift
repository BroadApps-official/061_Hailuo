import SwiftUI
import AVKit

struct MainContentView: View {
  @StateObject private var viewModel = EffectsViewModel()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Text("Hailuo")
              .font(Typography.title1Emphasized)
              .foregroundColor(.white)

            Spacer()
            ProBadgeButton()
          }
          .padding(.horizontal, 16)

          Text("Let's start creating")
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)

          StartCreatingSection()
            .padding(.horizontal, 16)

          if !viewModel.popularEffects.isEmpty {
              HStack {
                  Text("Popular effects")
                      .font(.headline)
                      .foregroundColor(.white)
                  Spacer()
                NavigationLink(destination: EffectsGridView(title: "Popular effects", effects: viewModel.popularEffects)) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
              }
              .padding(.horizontal, 16)

              ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 12) {
                      ForEach(viewModel.popularEffects, id: \.id) { effect in
                          NavigationLink(destination: EffectDetailView(selectedEffect: effect, effects: viewModel.popularEffects)) {
                              EffectCell(effect: effect)
                          }
                      }
                  }
                  .padding(.horizontal, 16)
              }
          }


          if !viewModel.allEffects.isEmpty {
            HStack {
              Text("All effects")
                .font(.headline)
                .foregroundColor(.white)
              Spacer()
              NavigationLink(destination: EffectsGridView(title: "All effects", effects: viewModel.allEffects)) {
                HStack(spacing: 4) {
                    Text("See all")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )
              }
            }
            .padding(.horizontal, 16)

            EffectRow(effects: viewModel.allEffects)
          }
        }
        .padding(.top, 10)
      }
      .background(Color.black.edgesIgnoringSafeArea(.all))
      .onAppear {
        if viewModel.allEffects.isEmpty {
          Task {
            await viewModel.fetchEffects()
          }
        }
      }
    }
  }
}


struct StartCreatingSection: View {
  @State private var showTextToVideo = false
  @State private var showImageTextToVideo = false
  
  var body: some View {
    HStack(spacing: 20) {
      Button(action: {
        showTextToVideo = true
      }) {
        VStack {
          Image(systemName: "sparkles")
            .font(.title)
            .foregroundColor(.black)
          Text("Text to video")
            .font(Typography.footnoteEmphasized)
            .foregroundColor(.black)
        }
        .frame(width: 171, height: 70)
        .background(GradientStyle.background)
        .cornerRadius(10)
      }
      .foregroundColor(.white)
      .fullScreenCover(isPresented: $showTextToVideo) {
        TextToVideoView()
      }
      
      Button(action: {
        showImageTextToVideo = true
      }) {
        VStack {
          Image(systemName: "sparkles")
            .font(.title2)
            .foregroundColor(ColorPalette.Accent.primary)
          Text("Image&text to video")
            .font(Typography.footnoteEmphasized)
            .foregroundColor(ColorPalette.Accent.primary)
        }
        .frame(width: 171, height: 70)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
      }
      .foregroundColor(.white)
      .fullScreenCover(isPresented: $showImageTextToVideo) {
        ImageTextToVideoView()
      }
    }
  }
}


struct EffectRow: View {
  let effects: [Effect]
  
  let columns = [GridItem(.flexible()), GridItem(.flexible())]
  
  var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(effects, id: \.id) { effect in
        NavigationLink(destination: EffectDetailView(selectedEffect: effect, effects: effects)) {
          EffectCell(effect: effect)
        }
      }
    }
    .padding(.horizontal, 16)
  }
}

struct EffectCell: View {
  let effect: Effect
  @State private var isVideoLoaded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ZStack {
        Color.gray
          .frame(width: 171, height: 171)
          .cornerRadius(12)
        
        if let url = URL(string: effect.preview) {
          VideoLoopPlayerWithLoading(url: url, isLoaded: $isVideoLoaded, effectId: effect.id)
            .aspectRatio(2, contentMode: .fill)
            .frame(width: 171, height: 171)
            .cornerRadius(12)
        } else {
          ProgressView()
            .frame(width: 171, height: 171)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(12)
        }
      }
      
      Text(effect.title)
        .font(Typography.subheadlineEmphasized)
        .foregroundColor(.white)
        .padding(.leading, 6)
    }
  }
}


#Preview {
  MainContentView()
}
