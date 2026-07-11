import SwiftUI

struct AddFarmView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddFarmViewModel?

    var body: some View {
        Form {
            Section("Data Lahan") {
                TextField("Nama lahan", text: textBinding(\.name))
                TextField("Tanaman", text: textBinding(\.crop))
                TextField("Lokasi", text: textBinding(\.location))
                Toggle("Lahan aktif", isOn: Binding(
                    get: { viewModel?.isActive ?? true },
                    set: { viewModel?.isActive = $0 }))
            }

            if let errorMessage = viewModel?.errorMessage {
                Section { Text(errorMessage).foregroundStyle(RTDColor.warningRed) }
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if viewModel?.isLoading == true { ProgressView() }
                        Text(viewModel?.isLoading == true ? "Menyimpan..." : "Simpan Lahan")
                    }
                }
                .disabled(viewModel?.isLoading == true)
            }
        }
        .navigationTitle("Tambah Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Batal") { dismiss() }
            }
        }
        .task { if viewModel == nil { viewModel = env.makeAddFarmVM() } }
    }

    private func textBinding(_ keyPath: WritableKeyPath<AddFarmViewModel, String>) -> Binding<String> {
        Binding(
            get: { viewModel?[keyPath: keyPath] ?? "" },
            set: { viewModel?[keyPath: keyPath] = $0 }
        )
    }

    private func submit() async {
        guard let viewModel else { return }
        if await viewModel.save() { dismiss() }
    }
}