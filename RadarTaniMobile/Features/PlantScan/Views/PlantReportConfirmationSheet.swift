import SwiftUI

struct PlantReportConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let task: PlantAnalysisTask
    let diagnosis: AIPlantDiagnosis
    let onConfirm: (PlantReportOut) -> Void

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var hasDescription: Bool {
        !task.draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RTDSpacing.xl) {
                    confirmationHero
                    reportSummary
                    diagnosisSummary

                    if hasDescription {
                        symptomSummary
                    }

                    verificationNotice

                    if let errorMessage {
                        errorNotice(errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, RTDSpacing.md)
                .padding(.bottom, RTDSpacing.xl)
            }
            .scrollIndicators(.hidden)
            .background(RTDColor.background)
            .navigationTitle("Konfirmasi Laporan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(RTDColor.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(RTDColor.mutedBackground, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting)
                    .accessibilityLabel("Tutup")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionArea
            }
        }
        .background(RTDColor.background)
        .interactiveDismissDisabled(isSubmitting)
    }

    private var confirmationHero: some View {
        HStack(alignment: .top, spacing: RTDSpacing.lg) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 31, weight: .semibold))
                .foregroundStyle(RTDColor.deepGreen)
                .frame(width: 58, height: 58)
                .background(RTDColor.primaryGreen, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Kirim laporan ke koperasi?")
                    .font(.title2.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Periksa kembali informasi tanaman sebelum laporan masuk ke antrean verifikasi.")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RTDColor.softGreen, RTDColor.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(RTDColor.primaryGreen.opacity(0.45), lineWidth: 1)
        }
    }

    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: RTDSpacing.md) {
            sectionLabel("Ringkasan laporan", systemImage: "doc.text.image")

            HStack(alignment: .top, spacing: RTDSpacing.lg) {
                Image(uiImage: task.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 108, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(RTDColor.deepGreen.opacity(0.9), in: Circle())
                            .padding(7)
                    }
                    .accessibilityLabel("Foto tanaman pada laporan")

                VStack(alignment: .leading, spacing: 8) {
                    RTDBadge(title: task.draft.category.rawValue, color: RTDColor.warningOrange)

                    Text(task.draft.title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    reportMetadata(task.farm.name, systemImage: "leaf.fill")
                    reportMetadata(task.farm.location, systemImage: "mappin.and.ellipse")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .rtdCard(radius: 24)
    }

    private var diagnosisSummary: some View {
        VStack(alignment: .leading, spacing: RTDSpacing.lg) {
            sectionLabel("Hasil analisis AI", systemImage: "sparkles")

            HStack(alignment: .center, spacing: RTDSpacing.lg) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Perkiraan terdeteksi")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)

                    Text(diagnosis.prediction)
                        .font(.title3.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 2) {
                    Text("\(diagnosis.confidence)%")
                        .font(.title3.bold())
                        .foregroundStyle(RTDColor.deepGreen)
                        .monospacedDigit()
                    Text("keyakinan")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RTDColor.softGreen, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            ProgressView(value: Double(diagnosis.confidence), total: 100)
                .tint(RTDColor.leafGreen)
                .accessibilityLabel("Tingkat keyakinan AI")
                .accessibilityValue("\(diagnosis.confidence) persen")
        }
        .padding(18)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private var symptomSummary: some View {
        VStack(alignment: .leading, spacing: RTDSpacing.md) {
            sectionLabel("Ringkasan gejala", systemImage: "text.alignleft")

            Text(task.draft.description)
                .font(.callout)
                .foregroundStyle(RTDColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private var verificationNotice: some View {
        HStack(alignment: .top, spacing: RTDSpacing.md) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.title3)
                .foregroundStyle(RTDColor.infoBlue)
                .frame(width: 40, height: 40)
                .background(RTDColor.infoBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Proses selanjutnya")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                Text("Setelah dikirim, laporan berstatus Menunggu verifikasi dan dapat diperiksa oleh koperasi.")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.infoBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func errorNotice(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout.weight(.medium))
            .foregroundStyle(RTDColor.warningRed)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RTDColor.warningRed.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private var actionArea: some View {
        VStack(spacing: RTDSpacing.md) {
            Button {
                Task { await submit() }
            } label: {
                Group {
                    if isSubmitting {
                        HStack(spacing: RTDSpacing.sm) {
                            ProgressView()
                                .tint(RTDColor.textPrimary)
                            Text("Mengirim laporan…")
                        }
                    } else {
                        Label("Kirim Laporan", systemImage: "paperplane.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSubmitting)

            Button("Batal", role: .cancel) {
                dismiss()
            }
            .disabled(isSubmitting)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(RTDColor.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, RTDSpacing.md)
        .padding(.bottom, RTDSpacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(RTDColor.textSecondary)
    }

    private func reportMetadata(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(RTDColor.textSecondary)
            .lineLimit(2)
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let report = try await analysisStore.submitReport(taskID: task.id)
            dismiss()
            onConfirm(report)
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Laporan gagal disimpan ke server."
        }
    }
}
