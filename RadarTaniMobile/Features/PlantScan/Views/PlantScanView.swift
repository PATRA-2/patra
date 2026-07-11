import SwiftUI

struct PlantScanView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: PlantScanViewModel?
    @State private var activeFarmName: String = "Lahan Aktif"

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                RTDLoadingView()
            }
        }
        .background(RTDColor.background)
        .navigationTitle("Lapor")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let vm = env.makePlantScanVM()
                await vm.loadActiveFarm()
                activeFarmName = vm.activeFarm?.name ?? "Lahan Aktif"
                viewModel = vm
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: PlantScanViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FarmSelectorPill(farmName: activeFarmName, crop: "")

                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [RTDColor.deepGreen, RTDColor.leafGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "camera.macro")
                        .font(.system(size: 150))
                        .foregroundStyle(.white.opacity(0.12))
                        .offset(x: 120, y: -20)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lapor")
                            .font(.system(size: 32, weight: .bold))
                        Text("Foto gejala tanaman, dapatkan analisis AI, lalu bagikan ke Radar Feed.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.84))
                        Button { viewModel.didTapAmbilFoto() } label: {
                            Label("Ambil Foto", systemImage: "camera.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 10)
                    }
                    .foregroundStyle(.white)
                    .padding(24)
                }
                .frame(minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Panduan Laporan")
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    ForEach(viewModel.tips, id: \.self) { tip in
                        Label(tip, systemImage: "checkmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }
                .padding(18)
                .rtdCard()
            }
            .padding(20)
        }
        .confirmationDialog("Pilih Sumber Foto", isPresented: sourceSheetBinding(viewModel), titleVisibility: .visible) {
            Button("Kamera") { viewModel.selectSource(.camera) }
            Button("Galeri") { viewModel.selectSource(.photoLibrary) }
            Button("Batal", role: .cancel) {}
        }
        .sheet(isPresented: imagePickerBinding(viewModel)) {
            ImagePickerCoordinator(
                sourceType: viewModel.imagePickerSourceType,
                selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { viewModel.didPickImage($0) }
                )
            )
        }
        .alert("Izin Diperlukan", isPresented: permissionAlertBinding(viewModel)) {
            Button("Batal", role: .cancel) {}
            Button("Buka Pengaturan") { viewModel.openSettings() }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
        .navigationDestination(isPresented: navigateBinding(viewModel)) {
            if let image = viewModel.selectedImage {
                CreatePlantReportView(image: image, viewModel: viewModel)
            } else {
                Color.clear
            }
        }
    }

    private func sourceSheetBinding(_ vm: PlantScanViewModel) -> Binding<Bool> {
        Binding(get: { vm.showSourceSheet }, set: { vm.showSourceSheet = $0 })
    }
    private func imagePickerBinding(_ vm: PlantScanViewModel) -> Binding<Bool> {
        Binding(get: { vm.showImagePicker }, set: { vm.showImagePicker = $0 })
    }
    private func permissionAlertBinding(_ vm: PlantScanViewModel) -> Binding<Bool> {
        Binding(get: { vm.showPermissionAlert }, set: { vm.showPermissionAlert = $0 })
    }
    private func navigateBinding(_ vm: PlantScanViewModel) -> Binding<Bool> {
        Binding(get: { vm.navigateToCreateReport }, set: { vm.navigateToCreateReport = $0 })
    }
}