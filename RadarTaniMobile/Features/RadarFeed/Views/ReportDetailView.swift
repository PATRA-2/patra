import SwiftUI

struct ReportDetailView: View {
    let reportId: UUID
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: ReportDetailViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let report = viewModel?.report {
                    RTDAsyncImage(url: report.imageUrl)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(report.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(RTDColor.textPrimary)
                        HStack(spacing: 8) {
                            RTDBadge(title: report.category, color: RTDColor.warningOrange)
                            RTDBadge(title: report.status, color: statusColor(report.status))
                        }
                        Text(report.summary)
                            .font(.body)
                            .foregroundStyle(RTDColor.textSecondary)
                        Label("\(report.farmName) · \(report.createdAt, format: .relative(presentation: .named))",
                              systemImage: "leaf.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .padding(18)
                    .rtdCard()

                    if let diagnosis = report.diagnosis {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Analisis AI", subtitle: "Hasil deteksi")
                            HStack {
                                Text(diagnosis.prediction)
                                    .font(.headline)
                                    .foregroundStyle(RTDColor.textPrimary)
                                Spacer()
                                ConfidenceBadge(score: diagnosis.confidence)
                            }
                            Text(diagnosis.recommendation)
                                .font(.callout)
                                .foregroundStyle(RTDColor.textSecondary)
                        }
                        .padding(18)
                        .rtdCard()
                    }
                } else {
                    RTDLoadingView().frame(maxWidth: .infinity).padding(.vertical, 40)
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Detail Laporan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil { viewModel = env.makeReportDetailVM() }
            await viewModel?.load(id: reportId)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Terverifikasi": RTDColor.safeGreen
        case "Ditolak": RTDColor.warningRed
        default: RTDColor.warningOrange
        }
    }
}