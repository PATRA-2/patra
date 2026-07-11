import SwiftUI

struct NotificationListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: NotificationListViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Notifikasi", subtitle: "Status laporan dan peringatan terbaru")

                Toggle(
                    "Hanya yang belum dibaca",
                    isOn: Binding(
                        get: { viewModel?.unreadOnly ?? false },
                        set: { viewModel?.unreadOnly = $0 }
                    )
                )
                .onChange(of: viewModel?.unreadOnly) { _, _ in
                    Task { await viewModel?.load() }
                }

                if (viewModel?.items.isEmpty ?? false) && !(viewModel?.isLoading ?? false) {
                    RTDEmptyStateView(
                        title: "Belum ada notifikasi",
                        message: "Notifikasi laporan akan muncul di sini setelah laporan Anda diproses.",
                        systemImage: "bell.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .rtdCard()
                } else {
                    ForEach(viewModel?.items ?? []) { item in
                        NotificationCard(item: item) {
                            Task { await viewModel?.markRead(item.id) }
                        }
                    }

                    Button("Tandai Semua Dibaca") {
                        Task { await viewModel?.markAllRead() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Notifikasi")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil { viewModel = env.makeNotificationListVM() }
            await viewModel?.load()
        }
    }
}

struct NotificationCard: View {
    let item: NotificationOut
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: item.isRead ? "bell.fill" : "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(item.isRead ? RTDColor.textSecondary : RTDColor.warningOrange)
                    .frame(width: 40, height: 40)
                    .background(RTDColor.softGreen, in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    Text(item.message)
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.createdAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(RTDColor.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .rtdCard()
        }
        .buttonStyle(.plain)
    }
}
