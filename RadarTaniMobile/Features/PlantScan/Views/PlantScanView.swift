import SwiftUI

struct PlantScanView: View {
    @State private var viewModel = PlantScanViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FarmSelectorPill(farmName: viewModel.activeFarm.name, crop: viewModel.activeFarm.crop)

                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [RTDColor.deepGreen, RTDColor.leafGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "camera.macro")
                        .font(.system(size: 150))
                        .foregroundStyle(.white.opacity(0.12))
                        .offset(x: 120, y: -20)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lapor")
                            .font(.system(size: 32, weight: .bold))
                        Text("Foto gejala tanaman, dapatkan analisis AI, lalu bagikan ke Radar Feed.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.84))
                        Button {} label: {
                            Label("Ambil Foto", systemImage: "camera.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 10)
                    }
                    .foregroundStyle(.white)
                    .padding(24)
                }
                .frame(minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Panduan Laporan")
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    ForEach(viewModel.tips, id: \.self) { tip in
                        Label(tip, systemImage: "checkmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }
                .padding(18)
                .rtdCard()
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Lapor")
        .navigationBarTitleDisplayMode(.inline)
    }
}
