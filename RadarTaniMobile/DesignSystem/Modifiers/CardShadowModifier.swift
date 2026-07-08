import SwiftUI

struct CardShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}
