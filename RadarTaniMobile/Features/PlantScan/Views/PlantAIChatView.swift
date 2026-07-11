import SwiftUI

struct PlantAIChatView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: PlantAIChatViewModel?
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var crop = ""
    @State private var symptomNotes = ""
    @State private var showResult = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Analisis AI", subtitle: "Deteksi hama/penyakit dari foto tanaman")

                if let image {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if let result = viewModel?.diagnosisResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(result.prediction).font(.headline)
                            Spacer()
                            ConfidenceBadge(score: result.confidence)
                        }
                        Text(result.symptoms).font(.callout).foregroundStyle(.secondary)
                        Text("Rekomendasi: \(result.recommendation)").font(.callout)
                    }
                    .padding(16).rtdCard()
                }

                VStack(spacing: 12) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label(image == nil ? "Pilih Foto" : "Ganti Foto", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)

                    TextField("Jenis tanaman (opsional)", text: $crop)
                        .textFieldStyle(.roundedBorder)

                    TextField("Gejala (opsional)", text: $symptomNotes, axis: .vertical)
                        .lineLimit(3)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await analyze() }
                    } label: {
                        HStack {
                            if viewModel?.isLoading == true { ProgressView().tint(.white) }
                            Text(viewModel?.isLoading == true ? "Menganalisis..." : "Analisis dengan AI")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(image == nil || viewModel?.isLoading == true)

                    if let error = viewModel?.errorMessage {
                        Text(error).foregroundStyle(RTDColor.warningRed).font(.callout)
                    }
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Analisis AI")
        .navigationBarTitleDisplayMode(.inline)
        .task { if viewModel == nil { viewModel = env.makeAIChatVM() } }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerCoordinator(
                sourceType: .photoLibrary,
                selectedImage: $image)
        }
    }

    private func analyze() async {
        guard let image else { return }
        await viewModel?.analyze(
            image: image,
            crop: crop.isEmpty ? nil : crop,
            symptomNotes: symptomNotes.isEmpty ? nil : symptomNotes)
    }
}