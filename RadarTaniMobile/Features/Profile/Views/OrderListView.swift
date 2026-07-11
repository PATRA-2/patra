import SwiftUI

struct OrderListView: View {
    @Bindable var viewModel: OrderListViewModel
    @State private var showCreate = false

    var body: some View {
        List {
            if viewModel.orders.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "Belum ada pesanan",
                    systemImage: "cart",
                    description: Text("Pesan pestisida dari laporan untuk membuat pesanan baru.")
                )
            }
            ForEach(viewModel.orders) { order in
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.productName).font(.headline)
                    Text("\(order.quantity) unit").font(.subheadline).foregroundStyle(.secondary)
                    Text(order.status).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Pesanan Pestisida")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .task { if viewModel.orders.isEmpty { await viewModel.load() } }
        .sheet(isPresented: $showCreate) {
            CreateOrderSheet(viewModel: viewModel)
        }
    }
}

private struct CreateOrderSheet: View {
    @Bindable var viewModel: OrderListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var productName = ""
    @State private var quantity = 1
    @State private var relatedReportID: UUID?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Pesanan Baru") {
                    TextField("Nama produk", text: $productName)
                    Stepper("\(quantity) unit", value: $quantity, in: 1...10_000)
                    Picker("Laporan terkait", selection: $relatedReportID) {
                        Text("Tanpa laporan").tag(nil as UUID?)
                        ForEach(viewModel.relatedReports) { report in
                            Text(report.title).tag(report.id as UUID?)
                        }
                    }
                }
                if let errorMessage = viewModel.errorMessage {
                    Section { Text(errorMessage).foregroundStyle(RTDColor.warningRed) }
                }
            }
            .navigationTitle("Pesan Pestisida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Batal") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kirim") {
                        Task { await submit() }
                    }
                    .disabled(productName.isEmpty || isLoading)
                }
            }
        }
    }

    private func submit() async {
        isLoading = true; defer { isLoading = false }
        let success = await viewModel.create(
            productName: productName,
            quantity: quantity,
            relatedReportId: relatedReportID
        )
        if success { dismiss() }
    }
}
