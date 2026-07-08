import SwiftUI

struct LocationPermissionView: View {
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.largeTitle)
                .foregroundStyle(RTDColor.leafGreen)
            Text("Izinkan lokasi lahan")
                .font(.headline)
            Text("Lokasi digunakan untuk menghitung jarak laporan sekitar.")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
                .multilineTextAlignment(.center)
            Button("Izinkan Lokasi", action: onRequest)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .rtdCard()
    }
}
