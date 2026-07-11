import SwiftUI

struct CreatePlantReportView: View {
    let image: UIImage
    @Bindable var viewModel: PlantScanViewModel
    @Binding var path: [PlantScanRoute]

    @Environment(PlantAnalysisStore.self) private var analysisStore
    @State private var draft = PlantReportDraft()
    @State private var showTitleError = false

    private var trimmedTitle: String {
        draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        trimmedTitle.count >= 3 && viewModel.activeFarm != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ReportStepIndicator(activeStep: 2)
                photoPreview
                detailForm
                submitButton
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Detail Gejala")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draft.category = .disease
            draft.image = image
        }
    }

    private var photoPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityLabel("Preview foto tanaman")

            HStack(spacing: 10) {
                Button {
                    replaceImage(with: .camera)
                } label: {
                    Label("Ambil Ulang", systemImage: "camera.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    replaceImage(with: .photoLibrary)
                } label: {
                    Label("Pilih Foto Lain", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }
            .font(.callout.weight(.semibold))
            .tint(RTDColor.deepGreen)
        }
    }

    private var detailForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Kategori")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                Picker("Kategori laporan", selection: $draft.category) {
                    ForEach(PlantReportCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                RTDTextField(title: "Judul", text: $draft.title)
                    .onChange(of: draft.title) { _, _ in
                        if showTitleError { showTitleError = trimmedTitle.count < 3 }
                    }

                if showTitleError {
                    Label("Judul minimal 3 karakter.", systemImage: "exclamationmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.warningRed)
                }

                Text("Contoh: Bercak cokelat pada daun padi")
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Deskripsi")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                ZStack(alignment: .topLeading) {
                    if draft.description.isEmpty {
                        Text("Ceritakan gejala dan kapan mulai terlihat.")
                            .font(.body)
                            .foregroundStyle(RTDColor.textSecondary.opacity(0.72))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                    }

                    TextEditor(text: $draft.description)
                        .frame(minHeight: 124)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                }
                .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if let farm = viewModel.activeFarm {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Lahan laporan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(RTDColor.deepGreen)
                            .frame(width: 30, height: 30)
                            .background(RTDColor.softGreen, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(farm.name)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(RTDColor.textPrimary)
                            Text("\(farm.crop) · \(farm.location)")
                                .font(.caption)
                                .foregroundStyle(RTDColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(14)
                .background(RTDColor.softGreen.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Label("Pilih atau tambahkan lahan aktif terlebih dahulu.", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(RTDColor.warningRed)
            }
        }
        .padding(18)
        .rtdCard()
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Label("Kirim untuk dianalisis", systemImage: "sparkles")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.55)
        .accessibilityHint("Mengirim foto dan gejala ke proses analisis AI")
    }

    private func submit() {
        guard let farm = viewModel.activeFarm else { return }
        guard trimmedTitle.count >= 3 else {
            showTitleError = true
            return
        }

        draft.title = trimmedTitle
        let taskID = analysisStore.enqueue(image: image, draft: draft, farm: farm)
        path.append(.processing(taskID))
    }

    private func replaceImage(with source: UIImagePickerController.SourceType) {
        path.removeAll()
        viewModel.selectSource(source)
    }
}
