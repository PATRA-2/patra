import SwiftUI

struct DisclaimerCard: View {
    var body: some View {
        Label {
            Text("Hasil ini merupakan perkiraan awal berbasis AI dan bukan pengganti pemeriksaan langsung oleh penyuluh atau ahli pertanian.")
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle.fill")
        }
        .font(.caption)
        .foregroundStyle(RTDColor.textSecondary)
        .padding(16)
        .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18))
    }
}
