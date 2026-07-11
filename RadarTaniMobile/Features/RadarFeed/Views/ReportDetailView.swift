import SwiftUI

struct ReportDetailView: View {
    let reportId: UUID

    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: ReportDetailViewModel?

    var body: some View {
        Group {
            if let report = viewModel?.report {
                reportContent(report)
            } else if let errorMessage = viewModel?.errorMessage {
                errorState(errorMessage)
            } else {
                loadingState
            }
        }
        .background(RTDColor.background.ignoresSafeArea())
        .navigationTitle("Detail Laporan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = env.makeReportDetailVM()
            }
            await viewModel?.load(id: reportId)
        }
    }

    private func reportContent(_ report: PlantReportOut) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                reportHero(report)

                VStack(alignment: .leading, spacing: RTDSpacing.xl) {
                    reportOverview(report)
                    verificationStatus(report.status)

                    if let description = report.description,
                       !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       description != report.summary {
                        reportNotes(description)
                    }

                    if let diagnosis = report.diagnosis {
                        diagnosisSection(diagnosis)
                    }

                    reportLocation(report)
                }
                .padding(.horizontal, 20)
                .padding(.top, -38)
                .padding(.bottom, RTDSpacing.xxl)
            }
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await viewModel?.load(id: reportId)
        }
    }

    private func reportHero(_ report: PlantReportOut) -> some View {
        ZStack(alignment: .bottomLeading) {
            RTDAsyncImage(url: report.imageUrl)
                .frame(maxWidth: .infinity)
                .frame(height: 292)
                .clipped()
                .accessibilityLabel("Foto tanaman pada laporan \(report.title)")

            LinearGradient(
                colors: [.clear, RTDColor.textPrimary.opacity(0.62)],
                startPoint: .center,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            HStack(spacing: RTDSpacing.sm) {
                reportBadge(
                    report.category,
                    systemImage: categoryIcon(report.category),
                    tint: categoryColor(report.category)
                )
                reportBadge(
                    report.status,
                    systemImage: statusIcon(report.status),
                    tint: statusColor(report.status)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 56)
        }
        .frame(height: 292)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 34, bottomTrailingRadius: 34))
    }

    private func reportOverview(_ report: PlantReportOut) -> some View {
        VStack(alignment: .leading, spacing: RTDSpacing.lg) {
            VStack(alignment: .leading, spacing: RTDSpacing.sm) {
                Text(report.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(RTDColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(report.summary)
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(RTDColor.borderSoft)

            HStack(alignment: .top, spacing: RTDSpacing.md) {
                overviewMetadata(
                    title: "Lahan",
                    value: report.farmName,
                    systemImage: "leaf.fill",
                    tint: RTDColor.leafGreen
                )

                Rectangle()
                    .fill(RTDColor.borderSoft)
                    .frame(width: 1, height: 42)

                overviewMetadata(
                    title: "Dilaporkan",
                    value: report.createdAt.formatted(.relative(presentation: .named)),
                    systemImage: "clock.fill",
                    tint: RTDColor.infoBlue
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .shadow(color: RTDColor.deepGreen.opacity(0.09), radius: 18, x: 0, y: 9)
    }

    private func verificationStatus(_ status: String) -> some View {
        HStack(alignment: .top, spacing: RTDSpacing.md) {
            Image(systemName: statusIcon(status))
                .font(.title3.weight(.semibold))
                .foregroundStyle(statusColor(status))
                .frame(width: 44, height: 44)
                .background(
                    statusColor(status).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Status laporan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                Text(status)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                Text(statusDescription(status))
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            statusColor(status).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(statusColor(status).opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func reportNotes(_ description: String) -> some View {
        detailCard(
            title: "Catatan laporan",
            subtitle: "Keterangan dari pelapor",
            systemImage: "text.alignleft",
            tint: RTDColor.fieldOlive
        ) {
            Text(description)
                .font(.callout)
                .foregroundStyle(RTDColor.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func diagnosisSection(_ diagnosis: AIPlantDiagnosis) -> some View {
        detailCard(
            title: "Analisis AI",
            subtitle: "Perkiraan awal dari foto tanaman",
            systemImage: "sparkles",
            tint: RTDColor.deepGreen
        ) {
            VStack(alignment: .leading, spacing: RTDSpacing.lg) {
                HStack(alignment: .center, spacing: RTDSpacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Perkiraan terdeteksi")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)

                        Text(diagnosis.prediction)
                            .font(.title3.bold())
                            .foregroundStyle(RTDColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 1) {
                        Text("\(diagnosis.confidence)%")
                            .font(.title3.bold())
                            .foregroundStyle(RTDColor.deepGreen)
                            .monospacedDigit()
                        Text("keyakinan")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .background(
                        RTDColor.softGreen,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                }

                ProgressView(value: Double(diagnosis.confidence), total: 100)
                    .tint(RTDColor.leafGreen)
                    .accessibilityLabel("Tingkat keyakinan AI")
                    .accessibilityValue("\(diagnosis.confidence) persen")

                Divider()
                    .overlay(RTDColor.borderSoft)

                diagnosisRow(
                    title: "Gejala terdeteksi",
                    text: diagnosis.symptoms,
                    systemImage: "leaf.fill",
                    tint: RTDColor.warningOrange
                )

                diagnosisRow(
                    title: "Rekomendasi awal",
                    text: diagnosis.recommendation,
                    systemImage: "checklist",
                    tint: RTDColor.safeGreen
                )

                Label(
                    "Gunakan hasil AI sebagai panduan awal. Tunggu verifikasi koperasi sebelum mengambil tindakan lanjutan.",
                    systemImage: "info.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(RTDColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func reportLocation(_ report: PlantReportOut) -> some View {
        detailCard(
            title: "Lokasi laporan",
            subtitle: report.farmName,
            systemImage: "mappin.and.ellipse",
            tint: RTDColor.infoBlue
        ) {
            HStack(spacing: RTDSpacing.md) {
                coordinateValue("Lintang", value: report.coordinate.latitude)

                Rectangle()
                    .fill(RTDColor.borderSoft)
                    .frame(width: 1, height: 38)

                coordinateValue("Bujur", value: report.coordinate.longitude)
            }
        }
    }

    private func detailCard<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RTDSpacing.lg) {
            HStack(alignment: .center, spacing: RTDSpacing.md) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RTDColor.textSecondary)
                }
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private func diagnosisRow(title: String, text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: RTDSpacing.md) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.11), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func overviewMetadata(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: RTDSpacing.sm) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textPrimary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func coordinateValue(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RTDColor.textSecondary)
            Text(value.formatted(.number.precision(.fractionLength(5))))
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(RTDColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reportBadge(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(tint.opacity(0.92), in: Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.25), lineWidth: 1)
            }
    }

    private var loadingState: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(RTDColor.mutedBackground)
                    .frame(height: 292)

                VStack(alignment: .leading, spacing: RTDSpacing.lg) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(RTDColor.borderSoft)
                        .frame(width: 210, height: 26)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(RTDColor.borderSoft.opacity(0.75))
                        .frame(height: 15)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(RTDColor.borderSoft.opacity(0.75))
                        .frame(width: 250, height: 15)

                    HStack(spacing: RTDSpacing.sm) {
                        ProgressView()
                            .tint(RTDColor.deepGreen)
                        Text("Memuat detail laporan…")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .padding(.top, RTDSpacing.sm)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, -38)
            }
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Memuat detail laporan")
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: RTDSpacing.lg) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(RTDColor.warningRed)
                .frame(width: 64, height: 64)
                .background(
                    RTDColor.warningRed.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

            VStack(spacing: RTDSpacing.sm) {
                Text("Detail laporan belum dapat dimuat")
                    .font(.title3.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await viewModel?.load(id: reportId) }
            } label: {
                Label("Coba Lagi", systemImage: "arrow.clockwise")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: 420)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Hama": RTDColor.warningRed
        case "Penyakit": RTDColor.warningOrange
        case "Bibit": RTDColor.leafGreen
        case "Kerja Tani": RTDColor.infoBlue
        default: RTDColor.deepGreen
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Hama": "exclamationmark.triangle.fill"
        case "Penyakit", "Bibit": "leaf.fill"
        case "Kerja Tani": "person.2.fill"
        default: "doc.text.fill"
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Terverifikasi": RTDColor.safeGreen
        case "Ditolak": RTDColor.warningRed
        case "Aktif": RTDColor.infoBlue
        default: RTDColor.warningOrange
        }
    }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "Terverifikasi": "checkmark.seal.fill"
        case "Ditolak": "xmark.octagon.fill"
        case "Aktif": "dot.radiowaves.left.and.right"
        default: "clock.badge.checkmark.fill"
        }
    }

    private func statusDescription(_ status: String) -> String {
        switch status {
        case "Terverifikasi":
            "Koperasi telah memeriksa dan memverifikasi laporan ini."
        case "Ditolak":
            "Laporan tidak lolos verifikasi. Periksa kembali informasi yang dikirim."
        case "Aktif":
            "Laporan aktif dan dapat dilihat oleh petani di area sekitar."
        default:
            "Laporan sedang menunggu pemeriksaan dari koperasi."
        }
    }
}
