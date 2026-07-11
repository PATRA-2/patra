import SwiftUI

struct PlantReportSuccessView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    @Binding var path: [PlantScanRoute]

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ReportStepIndicator(activeStep: 4)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 86))
                    .foregroundStyle(RTDColor.safeGreen)
                    .symbolEffect(.bounce, value: task?.status)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Laporan berhasil dikirim")
                        .font(.largeTitle.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Koperasi akan memeriksa laporan sebelum mengirim peringatan kepada petani sekitar.")
                        .font(.body)
                        .foregroundStyle(RTDColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let task {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(task.draft.title)
                                    .font(.headline)
                                    .foregroundStyle(RTDColor.textPrimary)
                                Label(task.farm.name, systemImage: "leaf.fill")
                                    .font(.callout)
                                    .foregroundStyle(RTDColor.textSecondary)
                            }
                            Spacer()
                            RTDBadge(
                                title: task.report?.status ?? "Menunggu verifikasi",
                                color: RTDColor.infoBlue
                            )
                        }

                        Divider()

                        Label(
                            "Laporan juga tersedia pada History Laporan di halaman Profil.",
                            systemImage: "clock.arrow.circlepath"
                        )
                        .font(.callout)
                        .foregroundStyle(RTDColor.textSecondary)
                    }
                    .padding(18)
                    .rtdCard()
                }

                VStack(spacing: 12) {
                    Button {
                        path.removeAll()
                    } label: {
                        Label("Kembali ke Lapor", systemImage: "camera.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        path = [.tasks]
                    } label: {
                        Label("Lihat Semua Proses", systemImage: "tray.full.fill")
                            .font(.headline)
                            .foregroundStyle(RTDColor.deepGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(RTDColor.softGreen, in: Capsule())
                    }
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationBarBackButtonHidden(true)
    }
}
