import SwiftUI

struct FarmListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: FarmListViewModel?
    @State private var showAddFarm = false
    @State private var deleteConfirmation: DeleteConfirmation?
    @State private var showForceDeleteAlert = false
    @State private var pendingForceDelete: FarmOut?

    struct DeleteConfirmation: Identifiable {
        let id = UUID()
        let farm: FarmOut
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

                if let message = viewModel.errorMessage, viewModel.farms.isEmpty {
                    RTDErrorView(message: message)
                }
            }
        }
        .listStyle(.plain)
        .background(RTDColor.background)
        .navigationTitle("Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddFarm = true } label: {
                    Image(systemName: "plus").font(.title3)
                }
            }
        }
        .refreshable { await viewModel?.load() }
        .task {
            if viewModel == nil { viewModel = env.makeFarmListVM() }
            await viewModel?.load()
        }
        .sheet(isPresented: $showAddFarm) {
            NavigationStack { AddFarmView() }
                .onDisappear { Task { await viewModel?.load() } }
        }
        .alert("Hapus Lahan?", isPresented: .init(
            get: { deleteConfirmation != nil },
            set: { if !$0 { deleteConfirmation = nil } }
        )) {
            if let farm = deleteConfirmation?.farm {
                Button("Hapus", role: .destructive) {
                    Task { await delete(farm) }
                }
                Button("Batal", role: .cancel) {
                    deleteConfirmation = nil
                }
            }
        } message: {
            if let farm = deleteConfirmation?.farm {
                Text("Lahan '\(farm.name)' akan dihapus dari daftar Anda.")
            }
        }
        .alert("Laporan Juga Ikut Terhapus", isPresented: $showForceDeleteAlert) {
            if let farm = pendingForceDelete {
                Button("Hapus Semua", role: .destructive) {
                    Task { await forceDelete(farm) }
                }
                Button("Batal", role: .cancel) {
                    pendingForceDelete = nil
                }
            }
        } message: {
            if let farm = pendingForceDelete {
                Text("Lahan '\(farm.name)' masih memiliki laporan. Semua laporan di lahan ini juga akan dihapus. Lanjutkan?")
            }
        }
    }

    private func delete(_ farm: FarmOut) async {
        deleteConfirmation = nil
        do {
            try await env.farms.delete(farm.id)
            await viewModel?.load()
        } catch let error as APIError {
            if case .server(let s) = error, s.code == "FARM_IN_USE" {
                pendingForceDelete = farm
                showForceDeleteAlert = true
            }
        } catch {
            // ignore — error untuk force delete akan di-handle di konfirmasi
        }
    }

    private func forceDelete(_ farm: FarmOut) async {
        pendingForceDelete = nil
        do {
            try await env.apiClient.requestVoid(APIRoute.farmDelete(farm.id, force: true))
            await viewModel?.load()
        } catch {
        }
    }
}

private struct FarmCard: View {
    let farm: FarmOut

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