import SwiftUI

enum RTDColor {
    static let primaryGreen = Color(hex: "#B7E83A")
    static let deepGreen = Color(hex: "#1F3D2B")
    static let leafGreen = Color(hex: "#6FAF3D")
    static let softGreen = Color(hex: "#EAF8C6")
    static let fieldOlive = Color(hex: "#7A8B3A")
    static let background = Color(hex: "#F2F4F1")
    static let cardBackground = Color(hex: "#FFFFFF")
    static let mutedBackground = Color(hex: "#EEF1EA")
    static let textPrimary = Color(hex: "#162116")
    static let textSecondary = Color(hex: "#6B7468")
    static let borderSoft = Color(hex: "#DDE4D5")
    static let warningRed = Color(hex: "#E5484D")
    static let warningOrange = Color(hex: "#F59E0B")
    static let safeGreen = Color(hex: "#35A852")
    static let infoBlue = Color(hex: "#3B82F6")
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(RTDColor.textPrimary)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(RTDColor.primaryGreen, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct CardBackground: ViewModifier {
    var radius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(RTDColor.borderSoft, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func rtdCard(radius: CGFloat = 24) -> some View {
        modifier(CardBackground(radius: radius))
    }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: value).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
