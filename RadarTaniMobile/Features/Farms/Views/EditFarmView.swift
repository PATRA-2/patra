import SwiftUI

struct EditFarmView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Binding var farm: Farm

    @State private var name: String
    @State private var crop: String
    @State private var location: String
    @State private var isActive: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(farm: Binding<Farm>) {
        self._farm = farm
        let value = farm.wrappedValue
        self._name = State(initialValue: value.name)
        self._crop = State(initialValue: value.crop)
        self._location = State(initialValue: value.location)
        self._isActive = State(initialValue: value.isActive)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                introCard

                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Data Utama", systemImage: "leaf.circle.fill")

                    VStack(spacing: 16) {
                        RTDTextField(title: "Nama Lahan", prompt: "Contoh: Sawah Utara", text: $name)
                        RTDTextField(title: "Jenis Tanaman", prompt: "Contoh: Padi", text: $crop)
                    }
                    .textInputAutocapitalization(.words)
                    .padding(18)
                    .rtdCard(radius: 22)
                }

                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Lokasi", systemImage: "mappin.and.ellipse")

                    VStack(alignment: .leading, spacing: 14) {
                        RTDTextField(
                            title: "Nama Tempat, Desa, atau Daerah",
                            prompt: "Nama lokasi lahan",
                            text: $location
                        )
                        .textInputAutocapitalization(.words)

                        Label {
                            Text("Mengubah nama lokasi tidak memindahkan titik koordinat lahan.")
                                .font(.caption)
                                .foregroundStyle(RTDColor.textSecondary)
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(RTDColor.deepGreen)
                        }

                        Text(coordinateText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(RTDColor.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RTDColor.mutedBackground, in: Capsule())
                            .accessibilityLabel("Koordinat \(coordinateText)")
                    }
                    .padding(18)
                    .rtdCard(radius: 22)
                }

                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Status Lahan", systemImage: "checkmark.seal.fill")

                    Toggle(isOn: $isActive) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Jadikan Lahan Aktif")
                                .font(.headline)
                                .foregroundStyle(RTDColor.textPrimary)
                            Text(
                                isActive
                                    ? "Lahan ini digunakan untuk laporan dan pantauan baru."
                                    : "Lahan tidak digunakan sebagai konteks laporan utama."
                            )
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                        }
                    }
                    .tint(RTDColor.safeGreen)
                    .padding(18)
                    .rtdCard(radius: 22)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(RTDColor.warningRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RTDColor.warningRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
            .padding(.bottom, 96)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(RTDColor.background)
        .navigationTitle("Edit Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveButton
        }
    }

    private var introCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "square.and.pencil")
                .font(.title2.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
                .frame(width: 48, height: 48)
                .background(RTDColor.primaryGreen, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Perbarui data lahan")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text("Pastikan nama, tanaman, dan lokasi tetap sesuai kondisi lahan.")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(RTDColor.softGreen, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            if isSaving {
                ProgressView()
                    .tint(RTDColor.textPrimary)
            } else {
                Label("Simpan Perubahan", systemImage: "checkmark")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.55)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCrop: String {
        crop.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasChanges: Bool {
        trimmedName != farm.name ||
        trimmedCrop != farm.crop ||
        trimmedLocation != farm.location ||
        isActive != farm.isActive
    }

    private var canSave: Bool {
        !isSaving &&
        hasChanges &&
        trimmedName.count >= 2 &&
        trimmedCrop.count >= 2 &&
        trimmedLocation.count >= 3
    }

    private var coordinateText: String {
        String(format: "%.6f, %.6f", farm.coordinate.latitude, farm.coordinate.longitude)
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(RTDColor.textPrimary)
    }

    private func save() async {
        guard canSave else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let updated = try await env.farmStore.updateFarm(
                id: farm.id,
                name: trimmedName,
                crop: trimmedCrop,
                location: trimmedLocation,
                coordinate: farm.coordinate,
                isActive: isActive
            )
            farm = updated
            HapticManager.success()
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Lahan gagal diperbarui di server."
        }
    }
}
