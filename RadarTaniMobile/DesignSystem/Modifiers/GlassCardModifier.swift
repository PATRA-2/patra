import SwiftUI

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
