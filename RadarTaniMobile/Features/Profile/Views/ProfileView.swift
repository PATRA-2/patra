import SwiftUI

struct ProfileView: View {
    let userEmail: String
    let onLogout: () -> Void

    @State private var viewModel = ProfileViewModel()

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
                            Text(viewModel.name)
                                .font(.headline)
                                .foregroundStyle(RTDColor.textPrimary)
                            Text(userEmail)
                                .font(.callout)
                                .foregroundStyle(RTDColor.textSecondary)
                            Text(viewModel.cooperative)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RTDColor.leafGreen)
                        }
                    }
                }
                .padding(18)
                .rtdCard()

                VStack(spacing: 0) {
                    Toggle("Notifikasi", isOn: $viewModel.notificationsEnabled)
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
    }
}
