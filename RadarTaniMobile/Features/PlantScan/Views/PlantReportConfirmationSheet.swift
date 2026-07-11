import SwiftUI

struct PlantReportConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let task: PlantAnalysisTask
    let diagnosis: AIPlantDiagnosis
    let onConfirm: (PlantReportOut) -> Void

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Capsule()
                    .fill(RTDColor.borderSoft)
                    .frame(width: 44, height: 5)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Kirim laporan ke koperasi?")
                        .font(.title2.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                    Text("Periksa ringkasan sebelum laporan dibagikan.")
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                }

                HStack(alignment: .top, spacing: 14) {
                    Image(uiImage: task.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.draft.title)
                            .font(.headline)
                            .foregroundStyle(RTDColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        RTDBadge(title: task.draft.category.rawValue, color: RTDColor.warningOrange)
                        Label(task.farm.name, systemImage: "leaf.fill")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                        Label(task.farm.location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Perkiraan AI")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)
                    Text(diagnosis.prediction)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text("Confidence \(diagnosis.confidence)%")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(RTDColor.deepGreen)
                }
                .padding(16)
                .rtdCard(radius: 20)

                if !task.draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ringkasan gejala")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                        Text(task.draft.description)
                            .font(.callout)
                            .foregroundStyle(RTDColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .rtdCard(radius: 20)
                }

                Label(
                    "Setelah dikirim, laporan berstatus Menunggu verifikasi dan dapat diperiksa oleh koperasi.",
                    systemImage: "info.circle.fill"
                )
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(RTDColor.warningRed)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Kirim Laporan", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSubmitting)

                Button("Batal", role: .cancel) {
                    dismiss()
                }
                .disabled(isSubmitting)
                .font(.headline)
                .foregroundStyle(RTDColor.textSecondary)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .interactiveDismissDisabled(false)
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
