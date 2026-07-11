import SwiftUI

struct PlantDiagnosisResultView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    @Binding var path: [PlantScanRoute]
    @State private var showConfirmation = false

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ReportStepIndicator(activeStep: task?.status == .reported ? 4 : 3)

                if let task {
                    resultContent(task)
                } else {
                    ContentUnavailableView(
                        "Hasil tidak ditemukan",
                        systemImage: "exclamationmark.magnifyingglass",
                        description: Text("Kembali ke Lapor dan mulai analisis baru.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Hasil Analisis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConfirmation) {
            if let task, let diagnosis = task.diagnosis {
                PlantReportConfirmationSheet(task: task, diagnosis: diagnosis) { _ in
                    path.append(.success(task.id))
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private func resultContent(_ task: PlantAnalysisTask) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(uiImage: task.image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityLabel("Foto tanaman yang dianalisis")

            HStack(spacing: 8) {
                RTDBadge(title: task.draft.category.rawValue, color: RTDColor.warningOrange)
                RTDBadge(title: task.status.title, color: statusColor(task.status))
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            Text(task.draft.title)
                .font(.title2.bold())
                .foregroundStyle(RTDColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !task.draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(task.draft.description)
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label(task.farm.name, systemImage: "leaf.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
        }
        .padding(18)
        .rtdCard()

        if let diagnosis = task.diagnosis {
            diagnosisCard(diagnosis)
            actions(task: task)
        } else {
            VStack(spacing: 12) {
                ProgressView()
                Text(task.status == .failed ? "Analisis gagal" : "Analisis berjalan")
                    .font(.headline)
                    .foregroundStyle(task.status == .failed ? RTDColor.warningRed : RTDColor.textPrimary)
                Text(task.errorMessage ?? task.stageTitle)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .rtdCard()
        }
    }

    private func diagnosisCard(_ diagnosis: AIPlantDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Perkiraan awal AI", subtitle: "Gunakan sebagai bahan pemantauan, bukan keputusan akhir.")

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(diagnosis.prediction)
                        .font(.title3.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tingkat keyakinan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)
                }

                Spacer(minLength: 8)
                ConfidenceBadge(score: diagnosis.confidence)
            }

            Divider()

            diagnosisInfo(
                title: "Gejala terdeteksi",
                text: diagnosis.symptoms,
                systemImage: "leaf.fill",
                tint: RTDColor.leafGreen
            )

            diagnosisInfo(
                title: "Rekomendasi awal",
                text: diagnosis.recommendation,
                systemImage: "checklist",
                tint: RTDColor.deepGreen
            )

            DisclaimerCard()
        }
        .padding(18)
        .rtdCard()
    }

    private func diagnosisInfo(title: String, text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func actions(task: PlantAnalysisTask) -> some View {
        VStack(spacing: 12) {
            Button {
                path.append(.chat(task.id))
            } label: {
                Label("Tanya AI", systemImage: "message.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.deepGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(RTDColor.softGreen, in: Capsule())
            }
            .buttonStyle(.plain)

            if task.status == .reported {
                Label("Menunggu verifikasi koperasi", systemImage: "building.2.crop.circle.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.infoBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RTDColor.infoBlue.opacity(0.12), in: Capsule())
            } else {
                Button {
                    showConfirmation = true
                } label: {
                    Label("Laporkan ke Koperasi", systemImage: "paperplane.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func statusColor(_ status: PlantAnalysisStatus) -> Color {
        switch status {
        case .queued, .uploading, .analyzing:
            RTDColor.warningOrange
        case .completed:
            RTDColor.safeGreen
        case .failed:
            RTDColor.warningRed
        case .reported:
            RTDColor.infoBlue
        }
    }
}
