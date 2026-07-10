import SwiftUI

struct ReportHistoryView: View {
    let reportHistoryStore: ReportHistoryStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "History Laporan",
                    subtitle: "Laporan tanaman yang pernah Anda kirim ke Radar Feed"
                )

                if reportHistoryStore.reports.isEmpty {
                    RTDEmptyStateView(
                        title: "Belum ada laporan",
                        message: "Laporan yang dikirim dari tab Lapor akan tampil di sini.",
                        systemImage: "clock.arrow.circlepath"
                    )
                    .frame(maxWidth: .infinity)
                    .rtdCard()
                } else {
                    ForEach(reportHistoryStore.reports) { report in
                        ReportHistoryCard(report: report)
                    }
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("History Laporan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReportHistoryCard: View {
    let report: ReportHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(report.categoryColor)
                    .frame(width: 42, height: 42)
                    .background(report.categoryColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(report.title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(report.summary)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                RTDBadge(title: report.category, color: report.categoryColor)
                RTDBadge(title: report.status, color: statusColor)

                Spacer(minLength: 8)
            }

            Divider()
                .overlay(RTDColor.borderSoft)

            HStack(spacing: 10) {
                Label(report.farmName, systemImage: "leaf.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                Spacer(minLength: 8)

                Text(report.submittedDateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
            }
        }
        .padding(16)
        .rtdCard(radius: 18)
    }

    private var statusColor: Color {
        report.status == "Terverifikasi" ? RTDColor.safeGreen : RTDColor.infoBlue
    }
}

#Preview {
    NavigationStack {
        ReportHistoryView(reportHistoryStore: ReportHistoryStore())
    }
}
