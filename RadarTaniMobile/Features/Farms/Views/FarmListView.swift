import SwiftUI

struct FarmListView: View {
    @Environment(FarmStore.self) private var farmStore
    @Binding var selectedTab: MainTab
    @State private var farmPendingDeletion: Farm?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Lahan Saya", subtitle: "Kelola lahan aktif untuk radius laporan sekitar")

                if farmStore.farms.isEmpty {
                    RTDEmptyStateView(
                        title: "Belum ada lahan",
                        message: "Tambahkan lahan agar lokasi laporan dan peringatan sekitar dapat ditentukan.",
                        systemImage: "leaf.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .rtdCard()
                } else {
                    ForEach(farmStore.farms) { farm in
                        FarmCard(farm: farm) {
                            farmPendingDeletion = farm
                        }
                    }
                }

                NavigationLink {
                    AddFarmView(selectedTab: $selectedTab)
                } label: {
                    Label("Tambah Lahan", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Hapus lahan?",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible,
            presenting: farmPendingDeletion
        ) { farm in
            Button("Hapus Lahan", role: .destructive) {
                delete(farm)
            }
            Button("Batal", role: .cancel) {
                farmPendingDeletion = nil
            }
        } message: { farm in
            Text(deletionMessage(for: farm))
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { farmPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    farmPendingDeletion = nil
                }
            }
        )
    }

    private func deletionMessage(for farm: Farm) -> String {
        if farmStore.farms.count == 1 {
            return "\(farm.name) adalah satu-satunya lahan. Setelah dihapus, Anda perlu menambahkan lahan sebelum membuat laporan baru. Laporan lama tidak ikut terhapus."
        }

        if farm.isActive {
            return "\(farm.name) sedang aktif. Setelah dihapus, lahan berikutnya akan otomatis dijadikan aktif. Laporan lama tidak ikut terhapus."
        }

        return "\(farm.name) akan dihapus dari daftar lahan. Laporan lama tidak ikut terhapus."
    }

    private func delete(_ farm: Farm) {
        guard farmStore.deleteFarm(id: farm.id) != nil else { return }
        farmPendingDeletion = nil
        HapticManager.warning()
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTab = .farms

    NavigationStack {
        FarmListView(selectedTab: $selectedTab)
            .environment(FarmStore())
    }
}

private struct FarmCard: View {
    let farm: Farm
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: farm.isActive ? "checkmark.seal.fill" : "map.fill")
                .font(.title2)
                .foregroundStyle(farm.isActive ? RTDColor.primaryGreen : RTDColor.leafGreen)
                .frame(width: 48, height: 48)
                .background(RTDColor.softGreen, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(farm.name)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text("\(farm.crop) · \(farm.location)")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                Text(farm.isActive ? "Lahan aktif" : "Tidak aktif")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(farm.isActive ? RTDColor.safeGreen : RTDColor.textSecondary)
            }
            Spacer(minLength: 8)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RTDColor.warningRed)
                    .frame(width: 44, height: 44)
                    .background(RTDColor.warningRed.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hapus \(farm.name)")
            .accessibilityHint("Membuka konfirmasi hapus lahan")
        }
        .padding(18)
        .rtdCard()
    }
}
