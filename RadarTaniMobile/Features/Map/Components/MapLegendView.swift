import SwiftUI

struct MapLegendView: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem("Hama", color: RTDColor.warningRed)
            legendItem("Bibit", color: RTDColor.primaryGreen)
            legendItem("Kerja Tani", color: RTDColor.infoBlue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func legendItem(_ title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)
        }
    }
}
