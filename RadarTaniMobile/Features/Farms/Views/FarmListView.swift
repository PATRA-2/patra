import SwiftUI

struct FarmListView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedTab: MainTab
    @State private var viewModel: FarmListViewModel?
    @State private var deleteConfirmation: DeleteConfirmation?

    struct DeleteConfirmation: Identifiable {
        let id = UUID()
        let farm: Farm
    }

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.farms) { farm in
                    NavigationLink {
                        FarmDetailView(farm: farm)
                    } label: {
                        FarmCard(farm: farm)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Hapus", role: .destructive) {
                            deleteConfirmation = DeleteConfirmation(farm: farm)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(RTDColor.background)
        .navigationTitle("Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddFarmView(selectedTab: $selectedTab)
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                .accessibilityLabel("Tambah Lahan")
            }
        }
        .task {
            if viewModel == nil { viewModel = env.makeFarmListVM() }
        }
        .alert("Hapus Lahan?", isPresented: .init(
            get: { deleteConfirmation != nil },
            set: { if !$0 { deleteConfirmation = nil } }
        )) {
            if let farm = deleteConfirmation?.farm {
                Button("Hapus", role: .destructive) {
                    _ = viewModel?.delete(farm)
                    deleteConfirmation = nil
                }
                Button("Batal", role: .cancel) {
                    deleteConfirmation = nil
                }
            }
        } message: {
            if let farm = deleteConfirmation?.farm {
                Text("Lahan '\(farm.name)' akan dihapus dari daftar di perangkat ini.")
            }
        }
    }
}

private struct FarmCard: View {
    let farm: Farm

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
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
