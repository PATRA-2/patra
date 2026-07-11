import SwiftUI

struct ReportHistoryView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var reports: [PlantReportOut] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "History Laporan",
                    subtitle: "Laporan tanaman yang pernah Anda kirim ke Radar Feed"
                )

                if isLoading {
                    RTDLoadingView().frame(maxWidth: .infinity).padding(.vertical, 40)
                } else if let errorMessage {
                    RTDErrorView(message: errorMessage)
                    Button("Coba Lagi") { Task { await load() } }
                        .buttonStyle(PrimaryButtonStyle())
                } else if reports.isEmpty {
                    RTDEmptyStateView(
                        title: "Belum ada laporan",
                        message: "Laporan yang dikirim dari tab Lapor akan tampil di sini.",
                        systemImage: "clock.arrow.circlepath"
                    )
                    .frame(maxWidth: .infinity)
                    .rtdCard()
                } else {
                    ForEach(reports) { report in
                        ReportHistoryCard(item: ReportHistoryItem(from: report))
                            .contextMenu {
                                Button("Hapus Laporan", role: .destructive) {
                                    Task { await delete(report) }
                                }
                            }
                    }
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("History Laporan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true; defer { isLoading = false }
        do {
            reports = try await env.reports.list().items
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat riwayat."
        }
    }

    private func delete(_ report: PlantReportOut) async {
        do {
            try await env.reports.delete(report.id)
            await load()
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Laporan gagal dihapus dari server."
        }
    }
}

private struct ReportHistoryCard: View {
    let item: ReportHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(item.categoryColor)
                    .frame(width: 42, height: 42)
                    .background(item.categoryColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.summary)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                RTDBadge(title: item.category, color: item.categoryColor)
                RTDBadge(title: item.status, color: statusColor)

                Spacer(minLength: 8)
            }

            Divider()
                .overlay(RTDColor.borderSoft)

            HStack(spacing: 10) {
                Label(item.farmName, systemImage: "leaf.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                Spacer(minLength: 8)

                Text(item.submittedDateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
            }
        }
        .padding(16)
        .rtdCard(radius: 18)
    }

    private var statusColor: Color {
        item.status == "Terverifikasi" ? RTDColor.safeGreen : RTDColor.infoBlue
    }
}
