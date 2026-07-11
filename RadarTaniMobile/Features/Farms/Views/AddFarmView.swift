import MapKit
import SwiftUI

struct AddFarmView: View {
    @Environment(FarmStore.self) private var farmStore
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedTab: MainTab
    @State private var viewModel = AddFarmViewModel()
    @State private var locationManager = LocationManager()
    @StateObject private var placeSearchService = FarmPlaceSearchService()
    @State private var placeSelectionTask: Task<Void, Never>?
    @FocusState private var isLocationSearchFocused: Bool
    @State private var isShowingDiscardConfirmation = false

    var body: some View {
        Group {
            if viewModel.step == .success {
                successContent
            } else {
                wizardContent
            }
        }
        .background(RTDColor.background.ignoresSafeArea())
        .navigationTitle(viewModel.step.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if viewModel.step != .success {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: handleBack) {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Kembali")
                    .accessibilityHint("Kembali ke langkah sebelumnya")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.step != .success {
                primaryActionBar
            }
        }
        .confirmationDialog(
            "Buang perubahan lahan?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Buang Perubahan", role: .destructive) {
                dismiss()
            }
            Button("Lanjut Mengisi", role: .cancel) {}
        } message: {
            Text("Nama, tanaman, dan lokasi yang sudah diisi akan hilang.")
        }
        .animation(.snappy(duration: 0.28), value: viewModel.step)
        .task(id: viewModel.locationSearchText) {
            guard viewModel.step == .location else { return }
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
            } catch {
                return
            }

            let query = viewModel.locationSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard query != viewModel.trimmedLocationName || viewModel.coordinate == nil else {
                placeSearchService.clearSuggestions()
                return
            }
            placeSearchService.updateQuery(query)
        }
        .onDisappear {
            locationManager.stopLocationRequest()
            placeSelectionTask?.cancel()
            viewModel.cancelLocationLookup()
        }
    }

    private var wizardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AddFarmProgressView(step: viewModel.step)

                Group {
                    switch viewModel.step {
                    case .information:
                        informationStep
                    case .location:
                        locationStep
                    case .confirmation:
                        confirmationStep
                    case .success:
                        EmptyView()
                    }
                }
                .id(viewModel.step)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var informationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepIntroduction(
                systemImage: "leaf.circle.fill",
                title: "Kenali lahan Anda",
                message: "Nama dan jenis tanaman membantu laporan serta rekomendasi tampil sesuai konteks lahan."
            )

            VStack(alignment: .leading, spacing: 18) {
                RTDTextField(
                    title: "Nama lahan",
                    prompt: "Contoh: Sawah Utara",
                    text: $viewModel.name
                )
                .textInputAutocapitalization(.words)

                if !viewModel.name.isEmpty && viewModel.trimmedName.count < 3 {
                    validationMessage("Nama lahan minimal 3 karakter.")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Jenis tanaman")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)

                    Picker("Jenis tanaman", selection: $viewModel.selectedCrop) {
                        ForEach(FarmCropOption.allCases) { crop in
                            Text(crop.rawValue).tag(crop)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 50)
                    .background(
                        RTDColor.mutedBackground,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .accessibilityHint("Pilih tanaman utama pada lahan")
                }

                if viewModel.selectedCrop == .other {
                    RTDTextField(
                        title: "Jenis tanaman lainnya",
                        prompt: "Contoh: Kedelai",
                        text: $viewModel.customCrop
                    )
                    .textInputAutocapitalization(.words)

                    if !viewModel.customCrop.isEmpty && viewModel.resolvedCrop.count < 2 {
                        validationMessage("Jenis tanaman minimal 2 karakter.")
                    }
                }
            }
            .padding(18)
            .rtdCard()

            Label(
                "Lahan baru akan dijadikan lahan aktif dan digunakan saat membuat laporan tanaman.",
                systemImage: "checkmark.seal.fill"
            )
            .font(.callout)
            .foregroundStyle(RTDColor.deepGreen)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .background(RTDColor.softGreen, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepIntroduction(
                systemImage: "map.circle.fill",
                title: "Tandai lokasi lahan",
                message: "Koordinat digunakan untuk menghitung radius laporan dan peringatan di sekitar lahan."
            )

            VStack(alignment: .leading, spacing: 16) {
                locationSearchField

                if !placeSearchService.suggestions.isEmpty {
                    locationSuggestions
                } else if let errorMessage = placeSearchService.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(errorMessage, systemImage: "wifi.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(RTDColor.warningRed)
                            .fixedSize(horizontal: false, vertical: true)

                        if viewModel.coordinate != nil {
                            Button("Isi nama secara manual") {
                                viewModel.enableManualLocationEntry(
                                    message: "Saran lokasi belum dapat dimuat. Koordinat tetap tersimpan."
                                )
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.deepGreen)
                        }
                    }
                }

                FarmMapPickerView(
                    coordinate: $viewModel.coordinate,
                    locationManager: locationManager,
                    markerTitle: mapMarkerTitle,
                    onCoordinateSelected: handleMapCoordinateSelection,
                    onRegionChanged: placeSearchService.updateRegion
                )

                if viewModel.isResolvingLocation {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Mencari nama lokasi...")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                } else if !viewModel.trimmedLocationName.isEmpty,
                          let coordinate = viewModel.coordinate {
                    selectedLocationCard(coordinate: coordinate)
                }

                if let errorMessage = viewModel.locationLookupError {
                    Label(errorMessage, systemImage: "mappin.slash.fill")
                        .font(.callout)
                        .foregroundStyle(RTDColor.warningRed)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.allowsManualLocationEntry {
                    VStack(alignment: .leading, spacing: 8) {
                        RTDTextField(
                            title: "Nama lokasi manual",
                            prompt: "Contoh: Desa Sukamaju",
                            text: $viewModel.locationName
                        )
                        .textInputAutocapitalization(.words)

                        Text("Koordinat pin tetap digunakan. Isi nama tempat, desa, atau daerah minimal 3 karakter.")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !viewModel.locationName.isEmpty && viewModel.trimmedLocationName.count < 3 {
                    validationMessage("Nama lokasi minimal 3 karakter.")
                }
            }
            .padding(18)
            .rtdCard()
        }
    }

    private var locationSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cari nama tempat, desa, atau daerah")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(RTDColor.textSecondary)

                TextField(
                    "Contoh: Desa Sukamaju",
                    text: Binding(
                        get: { viewModel.locationSearchText },
                        set: viewModel.updateLocationSearchText
                    )
                )
                .focused($isLocationSearchFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

                if placeSearchService.isSearching {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Mencari saran lokasi")
                }

                if !viewModel.locationSearchText.isEmpty || viewModel.coordinate != nil {
                    Button {
                        placeSelectionTask?.cancel()
                        placeSearchService.clearSuggestions()
                        viewModel.clearLocationSelection()
                        isLocationSearchFocused = true
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hapus lokasi dan cari ulang")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(
                RTDColor.mutedBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
    }

    private var locationSuggestions: some View {
        VStack(spacing: 0) {
            ForEach(Array(placeSearchService.suggestions.enumerated()), id: \.offset) { index, suggestion in
                Button {
                    selectPlace(suggestion)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RTDColor.deepGreen)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(suggestion.title)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(RTDColor.textPrimary)
                                .multilineTextAlignment(.leading)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(RTDColor.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }

                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(suggestion.title), \(suggestion.subtitle)")

                if index < placeSearchService.suggestions.count - 1 {
                    Divider().padding(.leading, 48)
                }
            }
        }
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }

    private func selectedLocationCard(coordinate: Coordinate) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(RTDColor.safeGreen)

            VStack(alignment: .leading, spacing: 5) {
                Text("Lokasi dipilih")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(viewModel.trimmedLocationName)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                if !viewModel.detectedAddress.isEmpty {
                    Text(viewModel.detectedAddress)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(CoordinateFormatter.format(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ))
                .font(.caption.monospacedDigit())
                .foregroundStyle(RTDColor.textSecondary)
            }

            Spacer(minLength: 4)
        }
        .padding(14)
        .background(RTDColor.softGreen, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var mapMarkerTitle: String {
        if viewModel.isResolvingLocation { return "Mencari nama lokasi..." }
        return viewModel.trimmedLocationName.isEmpty
            ? "Lokasi lahan"
            : viewModel.trimmedLocationName
    }

    private func handleMapCoordinateSelection(_ coordinate: Coordinate) {
        placeSelectionTask?.cancel()
        placeSearchService.clearSuggestions()
        isLocationSearchFocused = false
        viewModel.resolveLocation(at: coordinate)
    }

    private func selectPlace(_ suggestion: MKLocalSearchCompletion) {
        placeSelectionTask?.cancel()
        isLocationSearchFocused = false
        placeSelectionTask = Task {
            do {
                let result = try await placeSearchService.select(suggestion)
                try Task.checkCancellation()
                viewModel.applyPlaceResult(result)
                placeSearchService.clearSuggestions()
                HapticManager.selection()
            } catch is CancellationError {
                return
            } catch {
                viewModel.enableManualLocationEntry(
                    message: "Nama lokasi belum ditemukan. Pilih titik pada peta atau isi nama secara manual."
                )
                placeSearchService.clearSuggestions()
            }
        }
    }

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepIntroduction(
                systemImage: "checkmark.circle.fill",
                title: "Periksa kembali",
                message: "Pastikan informasi dan titik lokasi sudah sesuai sebelum lahan disimpan."
            )

            VStack(spacing: 0) {
                confirmationRow(
                    title: "Nama lahan",
                    value: viewModel.trimmedName,
                    systemImage: "rectangle.and.pencil.and.ellipsis"
                )
                Divider().padding(.leading, 48)
                confirmationRow(
                    title: "Jenis tanaman",
                    value: viewModel.resolvedCrop,
                    systemImage: "leaf.fill"
                )
                Divider().padding(.leading, 48)
                confirmationRow(
                    title: "Lokasi",
                    value: viewModel.trimmedLocationName,
                    systemImage: "mappin.and.ellipse"
                )
                if let coordinate = viewModel.coordinate {
                    Divider().padding(.leading, 48)
                    confirmationRow(
                        title: "Koordinat",
                        value: CoordinateFormatter.format(
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        ),
                        systemImage: "location.fill"
                    )
                }
            }
            .padding(.horizontal, 18)
            .rtdCard()

            if let coordinate = viewModel.coordinate {
                FarmLocationPreview(coordinate: coordinate, title: viewModel.trimmedName)
                    .padding(12)
                    .rtdCard()
            }

            Label(
                "Saat disimpan, lahan aktif sebelumnya akan berubah menjadi tidak aktif.",
                systemImage: "info.circle.fill"
            )
            .font(.callout)
            .foregroundStyle(RTDColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var primaryActionBar: some View {
        VStack(spacing: 8) {
            Button(action: performPrimaryAction) {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(RTDColor.textPrimary)
                    } else {
                        Image(systemName: viewModel.step == .confirmation ? "checkmark.circle.fill" : "arrow.right")
                    }
                    Text(primaryActionTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canPerformPrimaryAction)
            .opacity(viewModel.canPerformPrimaryAction ? 1 : 0.48)
            .accessibilityHint(primaryActionHint)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var successContent: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 36)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(RTDColor.safeGreen)
                    .symbolEffect(.bounce, value: viewModel.savedFarm?.id)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Lahan berhasil ditambahkan")
                        .font(.largeTitle.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Lahan baru sudah aktif dan siap digunakan untuk laporan tanaman.")
                        .font(.body)
                        .foregroundStyle(RTDColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let farm = viewModel.savedFarm {
                    HStack(spacing: 14) {
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .foregroundStyle(RTDColor.deepGreen)
                            .frame(width: 50, height: 50)
                            .background(RTDColor.primaryGreen, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(farm.name)
                                .font(.headline)
                                .foregroundStyle(RTDColor.textPrimary)
                            Text("\(farm.crop) · \(farm.location)")
                                .font(.callout)
                                .foregroundStyle(RTDColor.textSecondary)
                            Text("Lahan aktif")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RTDColor.safeGreen)
                        }

                        Spacer()
                    }
                    .padding(18)
                    .rtdCard()
                }

                VStack(spacing: 12) {
                    Button {
                        startPlantReport()
                    } label: {
                        Label("Mulai Lapor", systemImage: "camera.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        dismiss()
                    } label: {
                        Label("Lihat Lahan", systemImage: "leaf.fill")
                            .font(.headline)
                            .foregroundStyle(RTDColor.deepGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RTDColor.cardBackground,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule().stroke(RTDColor.borderSoft, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }

    private func stepIntroduction(systemImage: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(RTDColor.deepGreen)
                .frame(width: 48, height: 48)
                .background(RTDColor.softGreen, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func validationMessage(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.caption)
            .foregroundStyle(RTDColor.warningRed)
    }

    private func confirmationRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
                .frame(width: 34, height: 34)
                .background(RTDColor.softGreen, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(RTDColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    private var primaryActionTitle: String {
        if viewModel.isSaving { return "Menyimpan lahan..." }
        return viewModel.step == .confirmation ? "Simpan Lahan" : "Lanjut"
    }

    private var primaryActionHint: String {
        viewModel.step == .confirmation
            ? "Menyimpan lahan sebagai lahan aktif"
            : "Melanjutkan ke langkah berikutnya"
    }

    private func performPrimaryAction() {
        switch viewModel.step {
        case .information, .location:
            HapticManager.selection()
            withAnimation(.snappy(duration: 0.28)) {
                viewModel.advance()
            }
        case .confirmation:
            Task {
                await viewModel.save(to: farmStore)
                if viewModel.step == .success {
                    HapticManager.success()
                }
            }
        case .success:
            break
        }
    }

    private func handleBack() {
        if viewModel.moveToPreviousStep() {
            HapticManager.selection()
        } else if viewModel.hasUnsavedChanges {
            isShowingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func startPlantReport() {
        dismiss()
        Task { @MainActor in
            await Task.yield()
            selectedTab = .plantScan
        }
    }
}

private struct AddFarmProgressView: View {
    let step: AddFarmStep

    private let labels = ["Informasi", "Lokasi", "Konfirmasi"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Langkah \(step.progressIndex) dari 3")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.leafGreen)

            HStack(spacing: 8) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    let stepNumber = index + 1
                    VStack(spacing: 7) {
                        Capsule()
                            .fill(stepNumber <= step.progressIndex ? RTDColor.primaryGreen : RTDColor.borderSoft)
                            .frame(height: 7)

                        Text(label)
                            .font(.caption2.weight(stepNumber == step.progressIndex ? .bold : .regular))
                            .foregroundStyle(
                                stepNumber == step.progressIndex
                                    ? RTDColor.textPrimary
                                    : RTDColor.textSecondary
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
        .padding(16)
        .rtdCard(radius: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Langkah \(step.progressIndex) dari 3, \(labels[step.progressIndex - 1])")
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTab = .farms

    NavigationStack {
        AddFarmView(selectedTab: $selectedTab)
            .environment(FarmStore())
    }
}
