import SwiftUI

struct FarmListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: FarmListViewModel?
    @State private var showAddFarm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Lahan Saya", subtitle: "Kelola lahan aktif untuk radius laporan sekitar")

                ForEach(viewModel?.farms ?? []) { farm in
                    FarmCard(farm: farm)
                }

                if let message = viewModel?.errorMessage, (viewModel?.farms.isEmpty ?? true) {
                    RTDErrorView(message: message)
                    Button("Coba lagi") { Task { await viewModel?.load() } }
                }

                Button { showAddFarm = true } label: {
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
        .task {
            if viewModel == nil { viewModel = env.makeFarmListVM() }
            await viewModel?.load()
        }
        .sheet(isPresented: $showAddFarm) {
            NavigationStack {
                AddFarmView()
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
            }
            Spacer()
        }
        .padding(18)
        .rtdCard()
    }
}