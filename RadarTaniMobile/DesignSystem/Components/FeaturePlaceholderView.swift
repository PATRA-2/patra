import SwiftUI

struct FeaturePlaceholderView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        RTDEmptyStateView(title: title, message: message, systemImage: systemImage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RTDColor.background)
    }
}
