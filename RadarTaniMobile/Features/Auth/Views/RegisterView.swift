import SwiftUI

struct RegisterView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RegisterViewModel?
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            RTDColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    formCard
                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Daftar sebagai Petani")
        .navigationBarTitleDisplayMode(.inline)
        .task { if viewModel == nil { viewModel = env.makeRegisterVM() } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Akun Petani", systemImage: "person.badge.plus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RTDColor.softGreen, in: Capsule())

            Text("Mulai pantau lahan dan laporan sekitar desa.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(RTDColor.textPrimary)

            Text("Isi data dasar petani agar Radar Tani bisa menyiapkan pengalaman yang relevan untuk lahan Anda.")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
        }
        .padding(.top, 8)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            registerField("Nama lengkap", icon: "person.fill", text: textBinding(\.name), prompt: "Nama petani", field: .name)
                .textContentType(.name)
                .submitLabel(.next)

            registerField("Email", icon: "envelope.fill", text: textBinding(\.email), prompt: "nama@email.com", field: .email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)

            registerField("Nama kelompok tani", icon: "person.3.fill", text: textBinding(\.cooperativeName), prompt: "Contoh: Koperasi Desa Sukamaju", field: .cooperative)
                .submitLabel(.next)

            registerField("Lokasi lahan utama", icon: "mappin.and.ellipse", text: textBinding(\.farmLocation), prompt: "Desa atau kecamatan", field: .farmLocation)
                .submitLabel(.next)

            registerField("Password", icon: "lock.fill", text: textBinding(\.password), prompt: "Minimal 6 karakter", field: .password, isSecure: true)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)

            if let errorMessage = viewModel?.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.warningRed)
            }

            Button { submitRegistration() } label: {
                HStack(spacing: 10) {
                    if viewModel?.isLoading == true { ProgressView().tint(RTDColor.textPrimary) }
                    Text(viewModel?.isLoading == true ? "Membuat akun..." : "Buat Akun Petani")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel?.isLoading == true)

            Button("Sudah punya akun? Masuk") {
                dismiss()
            }
            .font(.headline)
            .foregroundStyle(RTDColor.deepGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .disabled(viewModel?.isLoading == true)
        }
        .padding(20)
        .rtdCard(radius: 28)
    }

    private var privacyNote: some View {
        Label("Data kelompok dan lokasi lahan membantu menampilkan laporan sekitar. Identitas pribadi tetap tidak ditampilkan di Radar Feed.", systemImage: "hand.raised.fill")
            .font(.caption)
            .foregroundStyle(RTDColor.textSecondary)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 16)
    }

    private func textBinding(_ keyPath: WritableKeyPath<RegisterViewModel, String>) -> Binding<String> {
        Binding(
            get: { viewModel?[keyPath: keyPath] ?? "" },
            set: { viewModel?[keyPath: keyPath] = $0 }
        )
    }

    private func registerField(_ title: String, icon: String, text: Binding<String>, prompt: String, field: Field, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(RTDColor.leafGreen)
                    .frame(width: 20)
                Group {
                    if isSecure {
                        SecureField(prompt, text: text)
                    } else {
                        TextField(prompt, text: text)
                    }
                }
                .focused($focusedField, equals: field)
                .onSubmit { focusNext(after: field) }
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(focusedField == field ? RTDColor.primaryGreen : .clear, lineWidth: 2)
            }
        }
    }

    private func focusNext(after field: Field) {
        switch field {
        case .name:
            focusedField = .email
        case .email:
            focusedField = .cooperative
        case .cooperative:
            focusedField = .farmLocation
        case .farmLocation:
            focusedField = .password
        case .password:
            submitRegistration()
        }
    }

    private func submitRegistration() {
        focusedField = nil
        Task { if let viewModel { _ = await viewModel.register() } }
    }

    private enum Field {
        case name
        case email
        case cooperative
        case farmLocation
        case password
    }
}