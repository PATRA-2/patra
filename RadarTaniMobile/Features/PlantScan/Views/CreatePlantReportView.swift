import SwiftUI

struct CreatePlantReportView: View {
    let image: UIImage
    @State private var draft = PlantReportDraft()
    @Environment(\.dismiss) private var dismiss

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
                }
                .padding(18)
                .rtdCard()

                Button {
                    // Local save only for this scope.
                    dismiss()
                } label: {
                    Label("Simpan Draft", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(draft.title.isEmpty)
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Buat Laporan")
        .navigationBarTitleDisplayMode(.inline)
    }
}
