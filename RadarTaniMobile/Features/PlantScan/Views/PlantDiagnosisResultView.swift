import SwiftUI

struct PlantDiagnosisResultView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    let reportHistoryStore: ReportHistoryStore
    @Binding var path: [PlantScanRoute]
    @State private var confirmation: PlantReportConfirmation?

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let task, let diagnosis = task.diagnosis {
                    ReportStepIndicator(activeStep: task.status == .reported ? 4 : 3)
                    resultHeader(task: task, diagnosis: diagnosis)
                    PlantPhotoPreviewCard(
                        image: task.image,
                        farmName: task.farm.name,
                        crop: task.farm.crop
                    )
                    DiagnosisScoreCard(score: diagnosis.confidence)
                    SymptomCard(text: diagnosis.symptoms)
                    RecommendationCard(text: diagnosis.recommendation)
                    DisclaimerCard()
                    resultActions(task: task)
                } else {
                    ContentUnavailableView(
                        "Hasil belum tersedia",
                        systemImage: "sparkles.rectangle.stack",
                        description: Text("Tunggu proses analisis selesai atau coba kembali dari daftar task.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Perkiraan Awal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $confirmation) { confirmation in
            if let task = analysisStore.task(withID: confirmation.id),
               let diagnosis = task.diagnosis {
                PlantReportConfirmationSheet(task: task, diagnosis: diagnosis) {
                    sendReport(task)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func resultHeader(
        task: PlantAnalysisTask,
        diagnosis: AIPlantDiagnosis
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RTDBadge(
                    title: task.status == .reported ? "Menunggu verifikasi" : "Perkiraan awal",
                    color: task.status == .reported ? RTDColor.infoBlue : RTDColor.warningOrange
                )
                Spacer()
                Label("AI", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RTDColor.deepGreen)
            }

            Text(diagnosis.prediction)
                .font(.largeTitle.bold())
                .foregroundStyle(RTDColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Gunakan hasil ini untuk pemantauan awal dan bahan laporan ke koperasi.")
                .font(.body)
                .foregroundStyle(RTDColor.textSecondary)
        }
    }

    @ViewBuilder
    private func resultActions(task: PlantAnalysisTask) -> some View {
        VStack(spacing: 12) {
            Button {
                path.append(.chat(task.id))
            } label: {
                Label("Tanya AI", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.deepGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RTDColor.softGreen, in: Capsule())
            }

            if task.status == .reported {
                Label("Laporan sudah diterima koperasi", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(RTDColor.safeGreen)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .rtdCard(radius: 20)
            } else {
                Button {
                    confirmation = PlantReportConfirmation(id: task.id)
                } label: {
                    Label("Laporkan ke Koperasi", systemImage: "building.2.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.bottom, 12)
    }

    private func sendReport(_ task: PlantAnalysisTask) {
        reportHistoryStore.submit(
            draft: task.draft,
            farmName: task.farm.name,
            status: "Menunggu verifikasi"
        )
        analysisStore.markReported(taskID: task.id)
        path.append(.success(task.id))
    }
}
