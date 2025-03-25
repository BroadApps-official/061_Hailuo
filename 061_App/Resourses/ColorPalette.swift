import SwiftUI

struct ColorPalette {
    struct Accent {
        static let primary = Color(hex: "#A5C3FF")
        static let primaryAlpha = Color(hex: "#FFEBCD").opacity(0.12)
        static let secondary = Color(hex: "#27A5FF")
        static let grey = Color(hex: "#63666F")
        static let green = Color(hex: "#15CC68")
        static let red = Color(hex: "#EC0D2A")
    }

    struct Label {
        static let primary = Color(hex: "#FFFFFF")
        static let primaryInvariably = Color(hex: "#FFFFFF")
        static let primaryInverted = Color(hex: "#000000")
        static let primaryInvertedInvariably = Color(hex: "#000000")
        static let secondary = Color(hex: "#FFFFFF").opacity(0.8)
        static let tertiary = Color(hex: "#FFFFFF").opacity(0.6)
        static let quaternary = Color(hex: "#FFFFFF").opacity(0.4)
        static let quintuple = Color(hex: "#FFFFFF").opacity(0.28)
    }

    struct Background {
        static let primary = Color(hex: "#131313")
        static let primaryAlpha = Color(hex: "#131313").opacity(0.94)
        static let secondary = Color(hex: "#2D2D2D")
        static let tertiary = Color(hex: "#FFFFFF").opacity(0.08)
        static let quaternary = Color(hex: "#FFFFFF").opacity(0.14)
        static let dim = Color(hex: "#000000").opacity(0.4)
    }

    struct Separator {
        static let primary = Color(hex: "#FFFFFF").opacity(0.24)
        static let secondary = Color(hex: "#FFFFFF").opacity(0.16)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: 
            (a, r, g, b) = (255, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct GradientStyle {
    static let background = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#A5C3FF"), Color(hex: "#B5FFFE")]),
        startPoint: .leading,
        endPoint: .trailing
    )

  static let gray = LinearGradient(
    gradient: Gradient(colors: [Color(hex: "#1E1E1E"), Color(hex: "#1E1E1E")]),
      startPoint: .leading,
      endPoint: .trailing
  )
}
