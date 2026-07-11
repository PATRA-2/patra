import SwiftUI

struct PlantScanView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedTab: MainTab
    @State private var viewModel: PlantScanViewModel?
    @State private var path: [PlantScanRoute] = []
    @State private var analysisStore = PlantAnalysisStore()

    init(selectedTab: Binding<MainTab>) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let viewModel {
                    dashboard(viewModel: viewModel)
                } else {
                    RTDLoadingView()
                }
            }
            .background(RTDColor.background)
            .navigationTitle("Lapor")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PlantScanRoute.self) { route in
                destination(for: route)
            }
        }
        .environment(analysisStore)
        .task {
            if viewModel == nil {
                let vm = env.makePlantScanVM()
                await vm.loadActiveFarm()
                viewModel = vm
            }
        }
        .onAppear {
            viewModel?.refreshActiveFarm()
        }
    }

    @ViewBuilder
    private func dashboard(viewModel: PlantScanViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                SectionHeader(
                    title: "Lapor",
                    subtitle: "Foto gejala tanaman, lihat perkiraan AI, lalu teruskan laporan ke koperasi."
                )

                if let activeFarm = viewModel.activeFarm {
                    activeFarmCard(activeFarm)
                    sourceActions(viewModel)
                    runningSummary
                    farmerGuide
                } else {
                    missingFarmCard
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.loadActiveFarm() }
        .confirmationDialog(
            "Pilih Sumber Foto",
            isPresented: sourceSheetBinding(viewModel),
            titleVisibility: .visible
        ) {
            Button("Kamera") { viewModel.selectSource(.camera) }
            Button("Galeri") { viewModel.selectSource(.photoLibrary) }
            Button("Batal", role: .cancel) {}
        }
        .sheet(isPresented: imagePickerBinding(viewModel)) {
            ImagePickerCoordinator(
                sourceType: viewModel.imagePickerSourceType,
                selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { image in
                        viewModel.didPickImage(image)
                        guard let image else { return }
                        analysisStore.prepare(image: image)
                        path = [.compose]
                    }
                )
            )
        }
        .alert("Izin Diperlukan", isPresented: permissionAlertBinding(viewModel)) {
            Button("Batal", role: .cancel) {}
            Button("Buka Pengaturan") { viewModel.openSettings() }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
    }

    @ViewBuilder
    private func destination(for route: PlantScanRoute) -> some View {
        switch route {
        case .compose:
            if let image = analysisStore.pendingImage, let viewModel, viewModel.activeFarm != nil {
                CreatePlantReportView(image: image, viewModel: viewModel, path: $path)
            } else {
                FlowUnavailableView(
                    title: "Foto belum tersedia",
                    message: "Kembali ke Lapor lalu ambil atau pilih foto tanaman.",
                    systemImage: "photo.badge.exclamationmark"
                )
            }
        case .processing(let taskID):
            PlantAnalysisProcessingView(taskID: taskID, path: $path)
        case .tasks:
            PlantAnalysisTaskListView(path: $path)
        case .result(let taskID):
            PlantDiagnosisResultView(taskID: taskID, path: $path)
        case .chat(let taskID):
            PlantAIChatView(taskID: taskID)
        case .success(let taskID):
            PlantReportSuccessView(taskID: taskID, path: $path)
        }
    }

    private func activeFarmCard(_ farm: FarmOut) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(RTDColor.deepGreen, RTDColor.primaryGreen)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Lahan aktif")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)
                    Text(farm.name)
                        .font(.title3.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                    Text("\(farm.crop) · \(farm.location)")
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 10) {
                Label("Lokasi laporan dari lahan ini", systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.deepGreen)
                Spacer(minLength: 8)
            }
            .padding(12)
            .background(RTDColor.softGreen.opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(18)
        .rtdCard()
    }

    private func sourceActions(_ viewModel: PlantScanViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mulai dari foto tanaman")
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)

            HStack(spacing: 12) {
                sourceButton(
                    title: "Ambil Foto",
                    subtitle: "Buka kamera",
                    systemImage: "camera.fill",
                    tint: RTDColor.deepGreen
                ) {
                    viewModel.selectSource(.camera)
                }

                sourceButton(
                    title: "Pilih dari Galeri",
                    subtitle: "Gunakan foto lama",
                    systemImage: "photo.on.rectangle.angled",
                    tint: RTDColor.leafGreen
                ) {
                    viewModel.selectSource(.photoLibrary)
                }
            }
        }
    }

    private func sourceButton(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RTDColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(RTDColor.borderSoft, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Membuka \(subtitle.lowercased()) untuk laporan tanaman")
    }

    @ViewBuilder
    private var runningSummary: some View {
        if analysisStore.tasks.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Background task")
                            .font(.headline)
                            .foregroundStyle(RTDColor.textPrimary)
                        Text("Analisis tetap bisa dipantau dari sini selama aplikasi aktif.")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    Spacer()
                    Button {
                        path.append(.tasks)
                    } label: {
                        Image(systemName: "tray.full.fill")
                            .font(.headline)
                            .foregroundStyle(RTDColor.deepGreen)
                            .frame(width: 40, height: 40)
                            .background(RTDColor.softGreen, in: Circle())
                    }
                    .accessibilityLabel("Lihat semua proses")
                }

                ForEach(analysisStore.tasks.prefix(2)) { task in
                    Button {
                        open(task)
                    } label: {
                        HStack(spacing: 12) {
                            Image(uiImage: task.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.draft.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(RTDColor.textPrimary)
                                    .lineLimit(1)
                                Label(task.status.title, systemImage: task.status.systemImage)
                                    .font(.caption)
                                    .foregroundStyle(statusTint(for: task.status))
                            }

                            Spacer()

                            if task.status.isRunning {
                                Text("\(Int(task.progress * 100))%")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(RTDColor.deepGreen)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(RTDColor.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    path.append(.tasks)
                } label: {
                    Label("Lihat Semua Proses", systemImage: "list.bullet.rectangle")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RTDColor.softGreen, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .rtdCard()
        }
    }

    private var farmerGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Alur laporan")
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)

            guideRow(number: "1", title: "Foto tanaman", message: "Pastikan daun atau batang yang bermasalah terlihat jelas.")
            guideRow(number: "2", title: "Isi gejala", message: "Tulis judul singkat dan deskripsi kapan gejala mulai terlihat.")
            guideRow(number: "3", title: "Cek hasil AI", message: "Gunakan hasil sebagai perkiraan awal sebelum melapor.")
            guideRow(number: "4", title: "Kirim ke koperasi", message: "Konfirmasi laporan agar masuk status Menunggu verifikasi.")
        }
        .padding(18)
        .rtdCard()
    }

    private func guideRow(number: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(RTDColor.textPrimary)
                .frame(width: 26, height: 26)
                .background(RTDColor.primaryGreen, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(RTDColor.textPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var missingFarmCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "leaf.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(RTDColor.deepGreen, RTDColor.primaryGreen)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tambahkan lahan aktif dulu")
                    .font(.title2.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                Text("Laporan membutuhkan nama lahan, jenis tanaman, dan lokasi agar koperasi bisa memeriksa konteks tanaman.")
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                selectedTab = .farms
            } label: {
                Label("Tambah Lahan", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(22)
        .rtdCard()
    }

    private func open(_ task: PlantAnalysisTask) {
        switch task.status {
        case .queued, .uploading, .analyzing, .failed:
            path.append(.processing(task.id))
        case .completed, .reported:
            path.append(.result(task.id))
        }
    }

    private func statusTint(for status: PlantAnalysisStatus) -> Color {
        switch status {
        case .queued, .uploading, .analyzing:
            RTDColor.warningOrange
        case .completed:
            RTDColor.safeGreen
        case .failed:
            RTDColor.warningRed
        case .reported:
            RTDColor.infoBlue
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
}

private struct FlowUnavailableView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .background(RTDColor.background)
    }
}
