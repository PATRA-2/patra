import SwiftUI

struct PlantDiagnosisResultView: View {
    let report: PlantReportOut

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RTDAsyncImage(url: report.imageUrl)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(report.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RTDColor.textPrimary)
                    HStack(spacing: 8) {
                        RTDBadge(title: report.category, color: RTDColor.warningOrange)
                        RTDBadge(title: report.status, color: statusColor)
                    }
                    if let summary = report.description {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }
                .padding(18)
                .rtdCard()

                if let diagnosis = report.diagnosis {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Analisis AI", subtitle: "Hasil deteksi gejala tanaman")
                        HStack {
                            Text(diagnosis.prediction)
                                .font(.headline)
                                .foregroundStyle(RTDColor.textPrimary)
                            Spacer()
                            ConfidenceBadge(score: diagnosis.confidence)
                        }
                        Text(diagnosis.symptoms)
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                        Text("Rekomendasi")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                        Text(diagnosis.recommendation)
                            .font(.callout)
                            .foregroundStyle(RTDColor.textPrimary)
                    }
                    .padding(18)
                    .rtdCard()
                } else {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Analisis sedang berjalan")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .rtdCard()
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Hasil Laporan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusColor: Color {
        switch report.status {
        case "Terverifikasi": RTDColor.safeGreen
        case "Ditolak": RTDColor.warningRed
        default: RTDColor.warningOrange
        }
    }
}