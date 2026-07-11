import MapKit
import SwiftUI

struct AddFarmView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: MainTab
    @State private var viewModel: AddFarmViewModel?
    @State private var showDiscardAlert = false

    init(selectedTab: Binding<MainTab>) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                RTDLoadingView()
            }
        }
        .background(RTDColor.background)
        .navigationTitle(viewModel?.isSuccess == true ? "Lahan Tersimpan" : viewModel?.step.title ?? "Tambah Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if viewModel?.isSuccess != true {
                ToolbarItem(placement: .topBarLeading) {
                    Button(viewModel?.step == .information ? "Batal" : "Kembali") {
                        handleBack()
                    }
                    .disabled(viewModel?.isSaving == true)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let viewModel, !viewModel.isSuccess {
                bottomCTA(viewModel)
            }
        }
        .alert("Buang perubahan?", isPresented: $showDiscardAlert) {
            Button("Buang", role: .destructive) { dismiss() }
            Button("Lanjut Edit", role: .cancel) {}
        } message: {
            Text("Data lahan yang sudah diisi akan hilang.")
        }
        .task { if viewModel == nil { viewModel = env.makeAddFarmVM() } }
    }

    @ViewBuilder
    private func content(_ viewModel: AddFarmViewModel) -> some View {
        if viewModel.isSuccess {
            successView(viewModel)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(viewModel.progressText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .accessibilityLabel(viewModel.progressText)

                    switch viewModel.step {
                    case .information: informationStep(viewModel)
                    case .location: locationStep(viewModel)
                    case .confirmation: confirmationStep(viewModel)
                    }
                }
                .padding(20)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func informationStep(_ viewModel: AddFarmViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nama Lahan")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                TextField("Nama lahan", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Jenis Tanaman")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                FlowLayout(spacing: 10) {
                    ForEach(viewModel.cropChoices) { crop in
                        Button {
                            viewModel.selectCrop(crop)
                        } label: {
                            Text(crop.rawValue)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(viewModel.selectedCrop == crop ? RTDColor.textPrimary : RTDColor.deepGreen)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.selectedCrop == crop ? RTDColor.primaryGreen : RTDColor.cardBackground,
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                                }
                        }
                        .accessibilityLabel("Pilih tanaman \(crop.rawValue)")
                    }
                }

                if viewModel.selectedCrop == .other {
                    TextField("Jenis tanaman", text: $viewModel.customCrop)
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }

            if let message = viewModel.validationMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(RTDColor.warningRed)
            }

            Label {
                Text("Lahan baru akan otomatis menjadi lahan aktif. Lahan aktif sebelumnya akan diganti setelah data tersimpan.")
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
            } icon: {
                Image(systemName: "leaf.circle.fill")
                    .font(.title2)
                    .foregroundStyle(RTDColor.deepGreen)
                    .accessibilityLabel("Informasi lahan aktif")
            }
            .padding(16)
            .background(RTDColor.cardBackground)
            .rtdCard(radius: 20)
        }
    }

    private func locationStep(_ viewModel: AddFarmViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cari Lokasi")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RTDColor.textSecondary)
                        .accessibilityLabel("Cari")

                    TextField("Cari nama tempat, desa, atau daerah", text: Binding(
                        get: { viewModel.locationQuery },
                        set: { viewModel.updateSearchText($0) }
                    ))
                    .textInputAutocapitalization(.words)

                    if !viewModel.locationQuery.isEmpty {
                        Button {
                            viewModel.clearLocation()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(RTDColor.textSecondary)
                        }
                        .accessibilityLabel("Bersihkan pencarian lokasi")
                    }
                }
                .padding(14)
                .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                }

                if viewModel.isSearching {
                    Label("Mencari nama lokasi...", systemImage: "location.magnifyingglass")
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                }

                if !viewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.suggestions, id: \.self) { completion in
                            Button {
                                viewModel.selectSuggestion(completion)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(completion.title)
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(RTDColor.textPrimary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(RTDColor.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                            }
                            .buttonStyle(.plain)

                            if completion != viewModel.suggestions.last {
                                Divider()
                                    .padding(.leading, 14)
                            }
                        }
                    }
                    .background(RTDColor.cardBackground)
                    .rtdCard(radius: 18)
                }
            }

            FarmMapPickerView(
                coordinate: viewModel.selectedCoordinate,
                markerTitle: viewModel.markerTitle,
                cameraPosition: Bindable(viewModel).cameraPosition,
                onCoordinateSelected: viewModel.selectCoordinate,
                onRegionChanged: viewModel.updateSearchRegion
            )
            .frame(height: 280)

            Button {
                viewModel.useCurrentLocation()
            } label: {
                if viewModel.isRequestingCurrentLocation {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Gunakan Lokasi Saya", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.headline)
            .foregroundStyle(RTDColor.deepGreen)
            .padding(.vertical, 14)
            .background(RTDColor.softGreen, in: Capsule())
            .disabled(viewModel.isRequestingCurrentLocation)

            if let message = viewModel.locationErrorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(RTDColor.warningRed)
            }

            if let message = viewModel.locationMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(message == "Mencari nama lokasi..." ? RTDColor.textSecondary : RTDColor.warningOrange)
            }

            if viewModel.selectedCoordinate != nil {
                selectedLocationCard(viewModel)
            }
        }
    }

    private func confirmationStep(_ viewModel: AddFarmViewModel) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            summaryCard(title: "Nama Lahan", value: viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines), icon: "leaf.fill")
            summaryCard(title: "Tanaman", value: viewModel.finalCrop, icon: "camera.macro")
            summaryCard(title: "Lokasi", value: viewModel.finalLocationName, icon: "mappin.and.ellipse")

            if !viewModel.selectedAddress.isEmpty {
                summaryCard(title: "Alamat", value: viewModel.selectedAddress, icon: "signpost.right.fill")
            }

            summaryCard(title: "Koordinat", value: viewModel.coordinateText, icon: "location.north.line.fill")

            FarmMapPickerView(
                coordinate: viewModel.selectedCoordinate,
                markerTitle: viewModel.markerTitle,
                cameraPosition: Bindable(viewModel).cameraPosition,
                onCoordinateSelected: { _ in },
                onRegionChanged: { _ in }
            )
            .frame(height: 180)

            Label {
                Text("Setelah disimpan, lahan aktif sebelumnya akan dinonaktifkan dan lahan ini menjadi lahan aktif baru.")
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(RTDColor.warningOrange)
                    .accessibilityLabel("Peringatan")
            }
            .padding(16)
            .background(RTDColor.cardBackground)
            .rtdCard(radius: 20)
        }
    }

    private func successView(_ viewModel: AddFarmViewModel) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 32)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 76, weight: .semibold))
                .foregroundStyle(RTDColor.safeGreen)
                .accessibilityLabel("Lahan berhasil disimpan")

            VStack(spacing: 8) {
                Text("Lahan Tersimpan")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RTDColor.textPrimary)
                Text(viewModel.savedFarm?.name ?? viewModel.name)
                    .font(.headline)
                    .foregroundStyle(RTDColor.deepGreen)
                Text("Lahan ini sekarang menjadi lahan aktif untuk laporan dan pantauan berikutnya.")
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Button("Lihat Lahan") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Mulai Lapor") {
                    selectedTab = .report
                    dismiss()
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(RTDColor.softGreen, in: Capsule())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RTDColor.background)
    }

    private func selectedLocationCard(_ viewModel: AddFarmViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Lokasi dipilih", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(RTDColor.deepGreen)

            Text(viewModel.finalLocationName.isEmpty ? "Nama lokasi belum diisi" : viewModel.finalLocationName)
                .font(.body)
                .foregroundStyle(RTDColor.textPrimary)

            if !viewModel.selectedAddress.isEmpty {
                Text(viewModel.selectedAddress)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
            }

            Text(viewModel.coordinateText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(RTDColor.textSecondary)
        }
        .padding(16)
        .background(RTDColor.cardBackground)
        .rtdCard(radius: 20)
    }

    private func summaryCard(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(RTDColor.deepGreen)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RTDColor.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RTDColor.cardBackground)
        .rtdCard(radius: 20)
    }

    private func bottomCTA(_ viewModel: AddFarmViewModel) -> some View {
        VStack(spacing: 10) {
            if let message = viewModel.validationMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(RTDColor.warningRed)
            }
            Button {
                if viewModel.step == .confirmation {
                    Task { await viewModel.save() }
                } else {
                    viewModel.goForward()
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text(viewModel.step == .confirmation ? "Simpan Lahan" : "Lanjut")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.step == .information ? !viewModel.canContinueInformation : viewModel.step == .location ? !viewModel.canContinueLocation : !viewModel.canSave)
        }
        .padding(20)
        .background(.ultraThinMaterial)
    }

    private func handleBack() {
        guard let viewModel else { dismiss(); return }
        guard !viewModel.isSaving else { return }
        if viewModel.goBack() { return }
        if viewModel.hasDraft { showDiscardAlert = true } else { dismiss() }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? 0)
        let height = rows.reduce(CGFloat.zero) { partialResult, row in
            partialResult + row.height
        } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentItems: [Item] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        let availableWidth = maxWidth > 0 ? maxWidth : .greatestFiniteMagnitude

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width
            if proposedWidth > availableWidth, !currentItems.isEmpty {
                rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
                currentItems = [Item(index: index, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentItems.append(Item(index: index, size: size))
                currentWidth = proposedWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
        }

        return rows
    }

    private struct Item {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        let items: [Item]
        let width: CGFloat
        let height: CGFloat
    }
}
