import SwiftUI

struct PlantDiagnosisResultView: View {
    let report: PlantReportOut

    @Environment(AppEnvironment.self) private var env
    @State private var currentReport: PlantReportOut

    init(report: PlantReportOut) {
        self.report = report
        self._currentReport = State(initialValue: report)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RTDAsyncImage(url: currentReport.imageUrl)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text(currentReport.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RTDColor.textPrimary)
                    HStack(spacing: 8) {
                        RTDBadge(title: currentReport.category, color: RTDColor.warningOrange)
                        RTDBadge(title: currentReport.status, color: statusColor)
                    }
                    if let desc = currentReport.description {
                        Text(desc)
                            .font(.body)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }
                .padding(18)
                .rtdCard()

                if let diagnosis = currentReport.diagnosis {
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
                        Text("Analisis sedang berjalan...")
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
        .task {
            await pollDiagnosis()
        }
    }

    private func pollDiagnosis() async {
        guard currentReport.diagnosis == nil,
              currentReport.status == "Analisis berjalan" || currentReport.status == "Menunggu verifikasi" else { return }

        for _ in 0..<30 {
            try? await Task.sleep(for: .seconds(2))
            do {
                let updated = try await env.reports.detail(currentReport.id)
                await MainActor.run { currentReport = updated }
                if updated.diagnosis != nil { break }
            } catch { break }
        }
    }

    private var statusColor: Color {
        switch currentReport.status {
        case "Terverifikasi": RTDColor.safeGreen
        case "Ditolak": RTDColor.warningRed
        default: RTDColor.warningOrange
        }
    }
}