import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: HomeTab
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                FarmSelectorPill(farmName: viewModel.activeFarm.name, crop: viewModel.activeFarm.crop)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Beranda")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Pantau lahan aktif, kirim laporan tanaman, dan lihat laporan sekitar lahan Anda.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.86))

                    Button { selectedTab = .report } label: {
                        Label("Buat Laporan", systemImage: "camera.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    ZStack(alignment: .bottomTrailing) {
                        LinearGradient(colors: [RTDColor.deepGreen, RTDColor.leafGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 150))
                            .foregroundStyle(.white.opacity(0.12))
                            .offset(x: 28, y: 30)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                HStack(spacing: 12) {
                    HomeMetricCard(title: "Lahan", value: "\(viewModel.farmCount)", systemImage: "map.fill", color: RTDColor.leafGreen)
                    HomeMetricCard(title: "Radius Feed", value: viewModel.feedRadius, systemImage: "location.fill", color: RTDColor.infoBlue)
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Aksi Cepat", subtitle: "Alur utama sesuai kebutuhan petani")

                    HomeActionRow(
                        title: "Lapor gejala tanaman",
                        subtitle: "Ambil foto, kirim ke AI, lalu bagikan hasil ke Radar Feed.",
                        systemImage: "camera.macro",
                        color: RTDColor.primaryGreen
                    ) {
                        selectedTab = .report
                    }

                    HomeActionRow(
                        title: "Cek Radar Feed",
                        subtitle: "Lihat laporan hama, bibit, dan kerja tani di sekitar lahan.",
                        systemImage: "dot.radiowaves.left.and.right",
                        color: RTDColor.infoBlue
                    ) {
                        selectedTab = .radarFeed
                    }

                    HomeActionRow(
                        title: "Kelola lahan",
                        subtitle: "Pastikan lahan aktif benar untuk radius laporan dan notifikasi.",
                        systemImage: "map.fill",
                        color: RTDColor.leafGreen
                    ) {
                        selectedTab = .farms
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Laporan Terbaru", subtitle: "Ringkasan sekitar \(viewModel.activeFarm.name)")

                    ForEach(viewModel.latestReports) { report in
                        HomeReportCard(report: report)
                    }
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Beranda")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HomeMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12), in: Circle())

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(RTDColor.textPrimary)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .rtdCard()
    }
}

private struct HomeActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RTDColor.textSecondary)
            }
            .padding(18)
            .rtdCard()
        }
        .buttonStyle(.plain)
    }
}

private struct HomeReportCard: View {
    let report: RadarReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryChip(title: report.category.rawValue, systemImage: report.category.icon, color: report.category.color, isSelected: false)
                Spacer()
                Text(report.distance)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
            }

            Text(report.title)
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)
            Text(report.summary)
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
        }
        .padding(18)
        .rtdCard()
    }
}
