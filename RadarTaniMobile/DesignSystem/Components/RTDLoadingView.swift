import SwiftUI

struct RTDLoadingView: View {
    var message = "Memuat data..."

    var body: some View {
        VStack(spacing: 12) {
            ProgressView().tint(RTDColor.deepGreen)
            Text(message).font(.callout).foregroundStyle(RTDColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
