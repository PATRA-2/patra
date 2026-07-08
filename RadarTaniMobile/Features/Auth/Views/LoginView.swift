import SwiftUI

struct LoginView: View {
    let onLogin: (String) -> Void

    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            RTDColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    formCard
                    footerText
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [RTDColor.deepGreen, Color(hex: "#365F2F"), RTDColor.fieldOlive], startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: "leaf.fill")
                .font(.system(size: 170))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 110, y: -30)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("Smart farming", systemImage: "leaf.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.16), in: Capsule())
                    Spacer()
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(RTDColor.primaryGreen)
                        .padding(12)
                        .background(.black.opacity(0.18), in: Circle())
                }
                .foregroundStyle(.white)

                Spacer(minLength: 70)
                Text("Radar Tani Desa")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Peringatan dini hama untuk petani dan koperasi desa.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.84))
            }
            .padding(24)
        }
        .frame(minHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: RTDColor.deepGreen.opacity(0.18), radius: 24, x: 0, y: 16)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Masuk")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(RTDColor.textPrimary)
            Text("Gunakan akun petani Anda untuk melihat laporan sekitar lahan.")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)

            loginField("Email", icon: "envelope.fill", text: $viewModel.email, prompt: "nama@email.com", field: .email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            loginField("Password", icon: "lock.fill", text: $viewModel.password, prompt: "Masukkan password", field: .password, isSecure: true)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.warningRed)
            }

            Button { submitLogin() } label: {
                HStack(spacing: 10) {
                    if viewModel.isLoading { ProgressView().tint(RTDColor.textPrimary) }
                    Text(viewModel.isLoading ? "Memeriksa akun..." : "Masuk")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading)

            Button("Daftar sebagai Petani") {}
                .font(.headline)
                .foregroundStyle(RTDColor.deepGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .disabled(viewModel.isLoading)
        }
        .padding(20)
        .rtdCard(radius: 28)
    }

    private var footerText: some View {
        Text("Data lahan digunakan untuk menghitung jarak laporan sekitar, bukan untuk menampilkan identitas pribadi.")
            .font(.caption)
            .foregroundStyle(RTDColor.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
    }

    private func loginField(_ title: String, icon: String, text: Binding<String>, prompt: String, field: Field, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(RTDColor.leafGreen)
                    .frame(width: 20)
                Group {
                    if isSecure { SecureField(prompt, text: text) } else { TextField(prompt, text: text) }
                }
                .focused($focusedField, equals: field)
                .submitLabel(field == .email ? .next : .go)
                .onSubmit { field == .email ? (focusedField = .password) : submitLogin() }
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(focusedField == field ? RTDColor.primaryGreen : .clear, lineWidth: 2) }
        }
    }

    private func submitLogin() {
        focusedField = nil
        Task {
            if let email = await viewModel.login() {
                onLogin(email)
            }
        }
    }

    private enum Field { case email, password }
}
