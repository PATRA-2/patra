import SwiftUI

struct PlantAnalysisProcessingView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    let taskID: UUID
    @Binding var path: [PlantScanRoute]
    @State private var didNavigateToResult = false

    private var task: PlantAnalysisTask? {
        analysisStore.task(withID: taskID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ReportStepIndicator(activeStep: 3)

                if let task {
                    analysisHero(task)
                    progressTimeline(task)
                    actionSection(task)
                } else {
                    ContentUnavailableView(
                        "Proses tidak ditemukan",
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
        .navigationTitle("Analisis AI")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Lapor") {
                    path.removeAll()
                }
                .accessibilityHint("Proses tetap berjalan di daftar background task")
            }
        }
        .onChange(of: task?.status) { _, newStatus in
            guard newStatus == .completed, !didNavigateToResult else { return }
            didNavigateToResult = true
            path.append(.result(taskID))
        }
    }

    private func analysisHero(_ task: PlantAnalysisTask) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(RTDColor.borderSoft, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: task.progress)
                    .stroke(
                        RTDColor.primaryGreen,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth, value: task.progress)

                Image(uiImage: task.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())

                if task.status == .analyzing {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(RTDColor.deepGreen)
                        .padding(10)
                        .background(RTDColor.primaryGreen, in: Circle())
                        .offset(x: 54, y: -54)
                        .symbolEffect(.pulse)
                }
            }
            .frame(width: 154, height: 154)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progres analisis \(Int(task.progress * 100)) persen")

            VStack(spacing: 6) {
                Text(task.status == .failed ? "Analisis tertunda" : "AI sedang membantu membaca gejala")
                    .font(.title2.bold())
                    .foregroundStyle(RTDColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(task.errorMessage ?? task.stageTitle)
                    .font(.body)
                    .foregroundStyle(
                        task.status == .failed ? RTDColor.warningRed : RTDColor.textSecondary
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Label(task.farm.name, systemImage: "leaf.fill")
                Spacer()
                Text("\(Int(task.progress * 100))%")
                    .fontWeight(.bold)
            }
            .font(.callout)
            .foregroundStyle(RTDColor.deepGreen)

            ProgressView(value: task.progress)
                .tint(task.status == .failed ? RTDColor.warningRed : RTDColor.primaryGreen)
        }
        .padding(22)
        .rtdCard()
    }

    private func progressTimeline(_ task: PlantAnalysisTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tahapan analisis")
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)

            AnalysisTimelineRow(
                title: "Foto diterima",
                subtitle: "Ukuran dan format foto sudah diperiksa.",
                state: task.progress >= 0.22 ? .complete : .waiting
            )
            AnalysisTimelineRow(
                title: "Membaca pola gejala",
                subtitle: "AI membandingkan warna, bercak, dan bentuk daun.",
                state: timelineState(currentProgress: task.progress, start: 0.22, complete: 0.8)
            )
            AnalysisTimelineRow(
                title: "Menyusun rekomendasi",
                subtitle: "Menyiapkan langkah pemantauan awal yang aman.",
                state: timelineState(currentProgress: task.progress, start: 0.8, complete: 1)
            )
        }
        .padding(18)
        .rtdCard()
    }

    @ViewBuilder
    private func actionSection(_ task: PlantAnalysisTask) -> some View {
        if task.status == .failed {
            Button {
                didNavigateToResult = false
                analysisStore.retry(taskID: task.id)
            } label: {
                Label("Coba Lagi", systemImage: "arrow.clockwise")
            }
            .buttonStyle(PrimaryButtonStyle())
        } else if task.status == .completed {
            Button {
                path.append(.result(task.id))
            } label: {
                Label("Lihat Hasil", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        } else {
            Button {
                path.removeAll()
            } label: {
                Label("Jalankan di Latar Belakang", systemImage: "rectangle.stack.badge.play")
            }
            .buttonStyle(PrimaryButtonStyle())

            Text("Analisis tetap berjalan selama aplikasi aktif. Anda dapat memantau progres dari halaman Lapor.")
                .font(.caption)
                .foregroundStyle(RTDColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func timelineState(
        currentProgress: Double,
        start: Double,
        complete: Double
    ) -> AnalysisTimelineRow.State {
        if currentProgress >= complete { return .complete }
        if currentProgress >= start { return .active }
        return .waiting
    }
}

private struct AnalysisTimelineRow: View {
    enum State {
        case waiting
        case active
        case complete
    }

    let title: String
    let subtitle: String
    let state: State

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())
                .symbolEffect(.pulse, isActive: state == .active)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var systemImage: String {
        switch state {
        case .waiting: "circle.dotted"
        case .active: "sparkles"
        case .complete: "checkmark.circle.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .waiting: RTDColor.textSecondary
        case .active: RTDColor.warningOrange
        case .complete: RTDColor.safeGreen
        }
    }
}
