import SwiftUI

struct CreatePlantReportView: View {
    let image: UIImage
    @Bindable var viewModel: PlantScanViewModel

    @State private var draft = PlantReportDraft()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToResult = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Detail Laporan")
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)

                    RTDTextField(title: "Judul", text: $draft.title)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kategori")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                        Picker("Kategori", selection: $draft.category) {
                            ForEach(PlantReportCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Deskripsi")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                        TextEditor(text: $draft.description)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.warningRed)
                    }
                }
                .padding(18)
                .rtdCard()

                Button {
                    Task { await submit() }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isLoading { ProgressView().tint(RTDColor.textPrimary) }
                        Label(viewModel.isLoading ? "Mengirim..." : "Kirim Laporan", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(draft.title.isEmpty || viewModel.isLoading)
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Buat Laporan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            if let report = viewModel.createdReport {
                PlantDiagnosisResultView(report: report)
            } else {
                Color.clear
            }
        }
    }

    private func submit() async {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let category = draft.category.rawValue
        let description = draft.description.isEmpty ? nil : draft.description
        let farmId = viewModel.activeFarm?.id
        let lat = viewModel.activeFarm?.coordinate.latitude
        let long = viewModel.activeFarm?.coordinate.longitude
        await viewModel.submitReport(title: title, category: category,
                                     description: description, farmId: farmId,
                                     latitude: lat, longitude: long)
        if viewModel.createdReport != nil {
            navigateToResult = true
        }
    }
}