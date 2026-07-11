import SwiftUI

struct ProfileView: View {
    let onLogout: () -> Void

    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProfileViewModel?
    @State private var ordersVM: OrderListViewModel?
    @State private var showOrders = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                profileHero

                if let errorMessage = viewModel?.errorMessage {
                    RTDErrorView(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                activitySection
                accountSection
                logoutSection

                Text("Radar Tani Desa")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .accessibilityLabel("Aplikasi Radar Tani Desa")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .refreshable { await viewModel?.load() }
        .background(RTDColor.background)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RTDColor.textSecondary)
                }
                .accessibilityLabel("Tutup Profil")
            }
        }
        .task {
            if viewModel == nil { viewModel = env.makeProfileVM() }
            if ordersVM == nil { ordersVM = env.makeOrderListVM() }
            await viewModel?.load()
        }
        .sheet(isPresented: $showOrders) {
            NavigationStack {
                OrderListView(viewModel: ordersVM ?? env.makeOrderListVM())
            }
        }
    }

    private var profileHero: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [RTDColor.deepGreen, Color(hex: "#315D34")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 164))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 36, y: 42)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    Text(profileInitials)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .frame(width: 58, height: 58)
                        .background(RTDColor.primaryGreen, in: Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.34), lineWidth: 2)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel?.name ?? "Petani")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(profileEmail)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Label("Petani", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RTDColor.primaryGreen, in: Capsule())
                }

                HStack(spacing: 11) {
                    Image(systemName: "building.2.fill")
                        .font(.headline)
                        .foregroundStyle(RTDColor.primaryGreen)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Koperasi")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.66))
                        Text(viewModel?.cooperative ?? "Koperasi")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: RTDColor.deepGreen.opacity(0.18), radius: 22, y: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profil \(viewModel?.name ?? "Petani"), \(profileEmail), koperasi \(viewModel?.cooperative ?? "Koperasi")")
    }

    private var activitySection: some View {
        profileSection(title: "Aktivitas", subtitle: "Pantau informasi dan kebutuhan pertanian") {
            NavigationLink {
                NotificationListView()
            } label: {
                ProfileMenuRow(
                    title: "Notifikasi",
                    subtitle: "Pembaruan laporan dan aktivitas akun",
                    systemImage: "bell.fill",
                    tint: RTDColor.warningOrange
                )
            }
            .buttonStyle(.plain)

            profileDivider

            NavigationLink {
                ReportHistoryView()
            } label: {
                ProfileMenuRow(
                    title: "History Laporan",
                    subtitle: "Lihat laporan tanaman yang pernah dikirim",
                    systemImage: "clock.arrow.circlepath",
                    tint: RTDColor.safeGreen
                )
            }
            .buttonStyle(.plain)

            profileDivider

            Button {
                showOrders = true
            } label: {
                ProfileMenuRow(
                    title: "Pesanan Pestisida",
                    subtitle: "Pantau status dan riwayat pesanan",
                    systemImage: "cart.fill",
                    tint: RTDColor.infoBlue
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var accountSection: some View {
        profileSection(title: "Akun & Dukungan", subtitle: "Kelola akun dan informasi aplikasi") {
            NavigationLink {
                AccountSettingsView()
            } label: {
                ProfileMenuRow(
                    title: "Pengaturan Akun",
                    subtitle: "Kelola informasi dan preferensi akun",
                    systemImage: "gearshape.fill",
                    tint: RTDColor.deepGreen
                )
            }
            .buttonStyle(.plain)

            profileDivider

            NavigationLink {
                PrivacyInfoView()
            } label: {
                ProfileMenuRow(
                    title: "Privasi",
                    subtitle: "Pelajari cara data Anda digunakan",
                    systemImage: "hand.raised.fill",
                    tint: RTDColor.leafGreen
                )
            }
            .buttonStyle(.plain)

            profileDivider

            NavigationLink {
                FeaturePlaceholderView(
                    title: "Bantuan",
                    message: "Pusat bantuan Radar Tani Desa akan segera tersedia.",
                    systemImage: "questionmark.circle.fill"
                )
            } label: {
                ProfileMenuRow(
                    title: "Bantuan",
                    subtitle: "Temukan panduan penggunaan aplikasi",
                    systemImage: "questionmark.circle.fill",
                    tint: RTDColor.fieldOlive
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var logoutSection: some View {
        Button(role: .destructive, action: onLogout) {
            Label("Keluar dari Akun", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .foregroundStyle(RTDColor.warningRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(RTDColor.warningRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(RTDColor.warningRed.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Mengakhiri sesi dan kembali ke halaman masuk")
    }

    private var profileDivider: some View {
        Divider().padding(.leading, 72)
    }

    private var profileEmail: String {
        guard let email = viewModel?.email, !email.isEmpty else { return "Memuat data akun…" }
        return email
    }

    private var profileInitials: String {
        let name = viewModel?.name ?? "Petani"
        let words = name.split(separator: " ").prefix(2)
        let initials = words.compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? "P" : initials.uppercased()
    }

    private func profileSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(RTDColor.borderSoft, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 14, y: 7)
        }
    }
}
