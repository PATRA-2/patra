import SwiftUI

struct PlantAnalysisTaskListView: View {
    @Environment(PlantAnalysisStore.self) private var analysisStore

    @Binding var path: [PlantScanRoute]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                SectionHeader(
                    title: "Background task",
                    subtitle: "Pantau foto yang masih diproses dan buka kembali hasil sebelumnya"
                )

                if analysisStore.tasks.isEmpty {
                    ContentUnavailableView(
                        "Belum ada proses",
                        systemImage: "tray",
                        description: Text("Foto yang dianalisis dari tab Lapor akan muncul di sini.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 70)
                } else {
                    taskSection(
                        title: "Berjalan",
                        subtitle: "Tetap diproses selama aplikasi aktif",
                        tasks: analysisStore.runningTasks
                    )
                    taskSection(
                        title: "Perlu Tindakan",
                        subtitle: "Coba ulang proses yang belum berhasil",
                        tasks: analysisStore.failedTasks
                    )
                    taskSection(
                        title: "Selesai",
                        subtitle: "Hasil analisis dan laporan terbaru",
                        tasks: analysisStore.completedTasks
                    )
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Background task")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func taskSection(
        title: String,
        subtitle: String,
        tasks: [PlantAnalysisTask]
    ) -> some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(RTDColor.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RTDColor.textSecondary)
                }

                ForEach(tasks) { task in
                    PlantAnalysisTaskRow(
                        task: task,
                        onOpen: { open(task) },
                        onRetry: { analysisStore.retry(taskID: task.id) }
                    )
                }
            }
        }
    }

    private func open(_ task: PlantAnalysisTask) {
        switch task.status {
        case .queued, .uploading, .analyzing, .failed:
            path.append(.processing(task.id))
        case .completed, .reported:
            path.append(.result(task.id))
        }
    }
}

private struct PlantAnalysisTaskRow: View {
    let task: PlantAnalysisTask
    let onOpen: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 14) {
                    Image(uiImage: task.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 74, height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.draft.title)
                            .font(.headline)
                            .foregroundStyle(RTDColor.textPrimary)
                            .lineLimit(2)

                        Label(task.farm.name, systemImage: "leaf.fill")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)

                        Text(task.createdAt.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(RTDColor.textSecondary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.textSecondary)
                        .padding(.top, 5)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Label(task.status.title, systemImage: task.status.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusTint)

                Spacer(minLength: 8)

                if task.status.isRunning {
                    Text("\(Int(task.progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                }
            }

            if task.status.isRunning {
                ProgressView(value: task.progress)
                    .tint(RTDColor.primaryGreen)
                    .accessibilityLabel(task.stageTitle)
            } else if task.status == .failed {
                HStack(alignment: .top, spacing: 10) {
                    Text(task.errorMessage ?? "Analisis belum berhasil.")
                        .font(.caption)
                        .foregroundStyle(RTDColor.warningRed)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Coba Lagi", action: onRetry)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.deepGreen)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .rtdCard(radius: 20)
        .accessibilityElement(children: .contain)
    }

    private var statusTint: Color {
        switch task.status {
        case .queued, .uploading, .analyzing: RTDColor.warningOrange
        case .completed: RTDColor.safeGreen
        case .failed: RTDColor.warningRed
        case .reported: RTDColor.infoBlue
        }
    }
}
