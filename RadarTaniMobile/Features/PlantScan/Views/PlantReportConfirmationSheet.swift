import SwiftUI

struct PlantReportConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let task: PlantAnalysisTask
    let diagnosis: AIPlantDiagnosis
    let onConfirm: () -> Void

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

                Label(
                    "Setelah dikirim, laporan berstatus Menunggu verifikasi dan dapat diperiksa oleh koperasi.",
                    systemImage: "info.circle.fill"
                )
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

                Button {
                    dismiss()
                    onConfirm()
                } label: {
                    Label("Kirim Laporan", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Batal", role: .cancel) {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(RTDColor.textSecondary)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .interactiveDismissDisabled(false)
    }
}
