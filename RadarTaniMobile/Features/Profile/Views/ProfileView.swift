import SwiftUI

struct ProfileView: View {
    let onLogout: () -> Void
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: ProfileViewModel?
    @State private var ordersVM: OrderListViewModel?
    @State private var showOrders = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Profil", subtitle: "Akun dan pengaturan Radar Tani Desa")

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(RTDColor.deepGreen)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel?.name ?? "Petani")
                                .font(.headline)
                                .foregroundStyle(RTDColor.textPrimary)
                            Text(viewModel?.email ?? "")
                                .font(.callout)
                                .foregroundStyle(RTDColor.textSecondary)
                            Text(viewModel?.cooperative ?? "Koperasi")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RTDColor.leafGreen)
                        }
                    }
                }
                .padding(18)
                .rtdCard()

                VStack(spacing: 0) {
                    Toggle("Notifikasi", isOn: Binding(
                        get: { viewModel?.notificationsEnabled ?? true },
                        set: { viewModel?.notificationsEnabled = $0 }))
                    Divider().padding(.vertical, 12)
                    NavigationLink {
                        ReportHistoryView()
                    } label: {
                        HStack {
                            Label("History Laporan", systemImage: "clock.arrow.circlepath")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.vertical, 12)
                    Button {
                        showOrders = true
                    } label: {
                        HStack {
                            Label("Pesanan Pestisida", systemImage: "cart.fill")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.vertical, 12)
                    Label("Bantuan", systemImage: "questionmark.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider().padding(.vertical, 12)
                    Button(role: .destructive, action: onLogout) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .font(.headline)
                .padding(18)
                .rtdCard()
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil { viewModel = env.makeProfileVM() }
            if ordersVM == nil { ordersVM = env.makeOrderListVM() }
        }
        .sheet(isPresented: $showOrders) {
            NavigationStack {
                OrderListView(viewModel: ordersVM ?? env.makeOrderListVM())
            }
        }
    }
}