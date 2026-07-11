import SwiftUI

struct PlantScanView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore
    @Environment(FarmStore.self) private var farmStore

    @Binding var selectedTab: MainTab
    @Binding var path: [PlantScanRoute]
    @State private var viewModel = PlantScanViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                activeFarmSection
                captureHero
                backgroundTaskSection
                guidanceSection
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Lapor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    path.append(.tasks)
                } label: {
                    Image(systemName: analysisStore.runningTasks.isEmpty ? "tray" : "tray.full.fill")
                        .symbolRenderingMode(.hierarchical)
                        .overlay(alignment: .topTrailing) {
                            if !analysisStore.runningTasks.isEmpty {
                                Text("\(analysisStore.runningTasks.count)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(RTDColor.warningOrange, in: Circle())
                                    .offset(x: 8, y: -7)
                            }
                        }
                }
                .accessibilityLabel("Daftar proses analisis")
                .accessibilityValue("\(analysisStore.runningTasks.count) proses berjalan")
            }
        }
        .confirmationDialog(
            "Pilih Sumber Foto",
            isPresented: $viewModel.showSourceSheet,
            titleVisibility: .visible
        ) {
            Button("Kamera") {
                viewModel.selectSource(.camera)
            }
            Button("Galeri") {
                viewModel.selectSource(.photoLibrary)
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Gunakan foto yang terang dan fokus pada bagian tanaman yang bergejala.")
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePickerCoordinator(
                sourceType: viewModel.imagePickerSourceType,
                selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { viewModel.didPickImage($0) }
                )
            )
        }
        .alert("Izin Diperlukan", isPresented: $viewModel.showPermissionAlert) {
            Button("Batal", role: .cancel) {}
            Button("Buka Pengaturan") {
                viewModel.openSettings()
            }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
        .onChange(of: viewModel.navigateToCreateReport) { _, shouldNavigate in
            guard shouldNavigate, let image = viewModel.selectedImage else { return }
            analysisStore.prepare(image: image)
            viewModel.navigateToCreateReport = false
            path.append(.compose)
        }
    }

    private var activeFarmSection: some View {
        Group {
            if let farm = farmStore.activeFarm {
                Button {
                    HapticManager.selection()
                    selectedTab = .farms
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(RTDColor.deepGreen)
                            .frame(width: 48, height: 48)
                            .background(RTDColor.primaryGreen, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lahan aktif")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RTDColor.leafGreen)
                            Text(farm.name)
                                .font(.headline)
                                .foregroundStyle(RTDColor.textPrimary)
                            Text("\(farm.crop) · \(farm.location)")
                                .font(.callout)
                                .foregroundStyle(RTDColor.textSecondary)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .padding(16)
                    .rtdCard(radius: 20)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Buka tab Lahan untuk mengganti lahan aktif")
            } else {
                Button {
                    selectedTab = .farms
                } label: {
                    Label("Tambahkan lahan sebelum membuat laporan", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(RTDColor.deepGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .rtdCard(radius: 20)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var captureHero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [RTDColor.deepGreen, RTDColor.leafGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "camera.macro")
                .font(.system(size: 150))
                .foregroundStyle(.white.opacity(0.11))
                .offset(x: 130, y: -45)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                RTDBadge(title: "Langkah 1 dari 4", color: RTDColor.primaryGreen)

                Text("Foto gejala tanaman")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Ambil foto daun atau batang yang bermasalah. AI akan memberi perkiraan awal sebelum Anda melapor ke koperasi.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    viewModel.didTapAmbilFoto()
                } label: {
                    Label("Ambil atau Pilih Foto", systemImage: "camera.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
                .disabled(farmStore.activeFarm == nil)
                .accessibilityHint("Buka pilihan kamera atau galeri")
            }
            .padding(24)
        }
        .frame(minHeight: 330)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var backgroundTaskSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(
                    title: "Proses Berjalan",
                    subtitle: "Analisis tetap berjalan saat Anda kembali ke halaman ini"
                )

                Spacer(minLength: 12)

                Button("Lihat Semua") {
                    path.append(.tasks)
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
            }

            if analysisStore.runningTasks.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(RTDColor.textSecondary)
                        .frame(width: 46, height: 46)
                        .background(RTDColor.mutedBackground, in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Belum ada proses aktif")
                            .font(.headline)
                            .foregroundStyle(RTDColor.textPrimary)
                        Text("Foto yang sedang dianalisis akan muncul di sini.")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }
                .padding(18)
                .rtdCard(radius: 20)
            } else {
                ForEach(analysisStore.runningTasks.prefix(2)) { task in
                    Button {
                        path.append(.processing(task.id))
                    } label: {
                        PlantAnalysisCompactRow(task: task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Foto yang membantu AI")
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)

            ForEach(Array(viewModel.tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .frame(width: 28, height: 28)
                        .background(RTDColor.softGreen, in: Circle())

                    Text(tip)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .rtdCard()
    }
}

private struct PlantAnalysisCompactRow: View {
    let task: PlantAnalysisTask

    var body: some View {
        HStack(spacing: 14) {
            Image(uiImage: task.image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(task.draft.title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text("\(Int(task.progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                }

                Text(task.stageTitle)
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
                    .lineLimit(1)

                ProgressView(value: task.progress)
                    .tint(RTDColor.primaryGreen)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(RTDColor.textSecondary)
        }
        .padding(14)
        .rtdCard(radius: 18)
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTab = .plantScan
    @Previewable @State var path: [PlantScanRoute] = []

    NavigationStack {
        PlantScanView(selectedTab: $selectedTab, path: $path)
    }
    .environment(PlantAnalysisStore())
    .environment(FarmStore())
}
