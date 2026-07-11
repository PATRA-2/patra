import SwiftUI

struct FarmListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: FarmListViewModel?
    @State private var showAddFarm = false

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.farms) { farm in
                    NavigationLink {
                        FarmDetailView(farm: farm)
                    } label: {
                        FarmCard(farm: farm)
                    }
                }
                .onDelete { indexSet in
                    Task { await delete(at: indexSet) }
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
    }

    private func delete(at indexSet: IndexSet) async {
        for index in indexSet {
            if let farm = viewModel?.farms[safe: index] {
                await viewModel?.delete(farm.id)
            }
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
                if farm.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID() { EmptyView() }
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