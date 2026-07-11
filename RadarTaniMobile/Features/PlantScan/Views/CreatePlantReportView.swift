import SwiftUI

struct CreatePlantReportView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore
    @Environment(FarmStore.self) private var farmStore

    let image: UIImage
    @Binding var path: [PlantScanRoute]
    @State private var draft = PlantReportDraft()

    private var trimmedTitle: String {
        draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAnalyze: Bool {
        trimmedTitle.count >= 3 && farmStore.activeFarm != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ReportStepIndicator(activeStep: 2)
                photoPreview
                farmSummary
                reportForm
            }
            .padding(20)
            .padding(.bottom, 86)
        }
        .background(RTDColor.background)
        .navigationTitle("Detail Gejala")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: analyzePhoto) {
                    Label("Analisis Foto", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canAnalyze)

                if !draft.title.isEmpty && trimmedTitle.count < 3 {
                    Text("Judul minimal 3 karakter.")
                        .font(.caption)
                        .foregroundStyle(RTDColor.warningRed)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    private var photoPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Foto tanaman", systemImage: "photo.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                Spacer()

                Button("Ambil Ulang") {
                    analysisStore.pendingImage = nil
                    path.removeAll()
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
            }

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    Label("Pastikan gejala terlihat jelas", systemImage: "viewfinder")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.56), in: Capsule())
                        .padding(14)
                }
                .accessibilityLabel("Foto tanaman yang akan dianalisis")
        }
        .padding(16)
        .rtdCard()
    }

    @ViewBuilder
    private var farmSummary: some View {
        if let farm = farmStore.activeFarm {
            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(RTDColor.deepGreen)
                    .frame(width: 44, height: 44)
                    .background(RTDColor.softGreen, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Lokasi laporan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)
                    Text(farm.name)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text("\(farm.crop) · \(farm.location)")
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(RTDColor.safeGreen)
            }
            .padding(16)
            .rtdCard(radius: 20)
        } else {
            Label("Pilih lahan aktif sebelum menganalisis foto.", systemImage: "exclamationmark.triangle.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(RTDColor.warningRed)
                .padding(16)
                .rtdCard(radius: 20)
        }
    }

    private var reportForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Ceritakan gejalanya")
                    .font(.title2.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                Text("Informasi Anda membantu AI memberi perkiraan yang lebih relevan.")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
            }

            RTDTextField(title: "Judul laporan", text: $draft.title)

            VStack(alignment: .leading, spacing: 8) {
                Text("Kategori")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                Picker("Kategori", selection: $draft.category) {
                    ForEach(PlantReportCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Pilih jenis gejala tanaman")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Deskripsi gejala")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)

                ZStack(alignment: .topLeading) {
                    if draft.description.isEmpty {
                        Text("Contoh: bercak terlihat sejak tiga hari lalu dan mulai menyebar ke daun lain.")
                            .font(.body)
                            .foregroundStyle(RTDColor.textSecondary.opacity(0.72))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $draft.description)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 130)
                        .padding(10)
                        .background(
                            RTDColor.mutedBackground,
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                }
            }
        }
        .padding(18)
        .rtdCard()
    }

    private func analyzePhoto() {
        guard canAnalyze, let farm = farmStore.activeFarm else { return }
        draft.title = trimmedTitle
        let taskID = analysisStore.enqueue(image: image, draft: draft, farm: farm)
        path.append(.processing(taskID))
    }
}

struct ReportStepIndicator: View {
    let activeStep: Int

    private let steps = ["Foto", "Detail", "Analisis", "Lapor"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                let step = index + 1

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(step <= activeStep ? RTDColor.primaryGreen : RTDColor.borderSoft)
                            .frame(width: 28, height: 28)

                        if step < activeStep {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(RTDColor.deepGreen)
                        } else {
                            Text("\(step)")
                                .font(.caption.bold())
                                .foregroundStyle(
                                    step == activeStep ? RTDColor.deepGreen : RTDColor.textSecondary
                                )
                        }
                    }

                    Text(title)
                        .font(.caption2.weight(step == activeStep ? .bold : .medium))
                        .foregroundStyle(
                            step == activeStep ? RTDColor.textPrimary : RTDColor.textSecondary
                        )
                }
                .frame(maxWidth: .infinity)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(step < activeStep ? RTDColor.primaryGreen : RTDColor.borderSoft)
                        .frame(height: 2)
                        .offset(y: -9)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Langkah \(activeStep) dari 4, \(steps[activeStep - 1])")
    }
}

#Preview {
    @Previewable @State var path: [PlantScanRoute] = []

    NavigationStack {
        CreatePlantReportView(
            image: UIImage(systemName: "leaf.fill") ?? UIImage(),
            path: $path
        )
    }
    .environment(PlantAnalysisStore())
    .environment(FarmStore())
}
