import SwiftUI

struct ImageToVideoView: View {
    @Environment(\.dismiss) var dismiss
    let effects: [Effect]
    let selectedEffect: Effect

    @State private var currentEffect: Effect?
    @State private var selectedTab: String = "I2V"
    @State private var selectedImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                    }

                    Spacer()

                    Text("Create")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Пустой элемент для центрирования заголовка
                    Image(systemName: "chevron.left")
                        .opacity(0)
                }
                .padding(.horizontal, 16)

                // Сегментированный контрол для выбора режима
                HStack(spacing: 10) {
                    ModeButton(title: "I2V", isSelected: selectedTab == "I2V") {
                        selectedTab = "I2V"
                    }
                    ModeButton(title: "T2V", isSelected: selectedTab == "T2V") {
                        selectedTab = "T2V"
                    }
                    ModeButton(title: "I&T2V", isSelected: selectedTab == "I&T2V") {
                        selectedTab = "I&T2V"
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Поле для загрузки изображения
                ImagePickerView(selectedImage: $selectedImage)
                    .padding(.top, 10)

                // Секция "Select an effect"
                Text("Select an effect")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                EffectGridView(effects: effects, selectedEffect: $currentEffect)
                    .frame(height: 200)
                    .padding(.horizontal, 16)

                Spacer()

                // Кнопка "Create"
                Button(action: { /* Логика создания */ }) {
                    Text("Create")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentEffect != nil ? GradientStyle.background : GradientStyle.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(currentEffect == nil)
                .padding(.horizontal, 16)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .onAppear {
            currentEffect = selectedEffect
        }
        .navigationBarBackButtonHidden()
    }
}

// 📌 Компонент для выбора режима (I2V, T2V, I&T2V)
struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.purple.opacity(0.8) : Color.gray.opacity(0.3))
                .cornerRadius(10)
        }
    }
}

// 📌 Компонент для выбора изображения
struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(height: 150)
                .overlay(
                    VStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 140)
                                .cornerRadius(10)
                        } else {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Add image")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.footnote)
                            }
                        }
                    }
                )
        }
        .padding(.horizontal, 16)
        .onTapGesture {
            // Открытие выбора изображения
        }
    }
}

struct EffectGridView: View {
    let effects: [Effect]
    @Binding var selectedEffect: Effect?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(effects, id: \.id) { effect in
                    ZStack(alignment: .topTrailing) {
                        EffectCell(effect: effect)
                            .frame(width: 171, height: 171)

                        if selectedEffect?.id == effect.id {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LinearGradient(gradient: Gradient(colors: [.purple, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                                .frame(width: 171, height: 171)
                                .offset(y: -10)
                            
                            Image("check")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .offset(x: 10, y: -20)
                        }
                    }
                    .onTapGesture {
                        withAnimation {
                            selectedEffect = effect
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// 📌 Заглушка под видео (можно заменить на `VideoLoopPlayer`)
struct ImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.5))
    }
}

