import SwiftUI

struct PrimaryBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(RTDColor.background.ignoresSafeArea())
    }
}
