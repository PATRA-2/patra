import SwiftUI

struct RTDEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage).font(.largeTitle).foregroundStyle(RTDColor.leafGreen)
            Text(title).font(.headline).foregroundStyle(RTDColor.textPrimary)
            Text(message).font(.callout).foregroundStyle(RTDColor.textSecondary).multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
