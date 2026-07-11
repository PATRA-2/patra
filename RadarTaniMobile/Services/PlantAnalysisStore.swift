import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PlantAnalysisStore {
    private(set) var tasks: [PlantAnalysisTask]
    private(set) var respondingChatTaskIDs: Set<UUID> = []
    var pendingImage: UIImage?

    @ObservationIgnored private let analysisService: any PlantAnalysisService
    @ObservationIgnored private let chatService: any PlantAIChatService
    @ObservationIgnored private var runners: [UUID: Task<Void, Never>] = [:]

    init(
        tasks: [PlantAnalysisTask]? = nil,
        analysisService: (any PlantAnalysisService)? = nil,
        chatService: (any PlantAIChatService)? = nil
    ) {
        self.tasks = tasks ?? []
        self.analysisService = analysisService ?? MockPlantAnalysisService()
        self.chatService = chatService ?? MockPlantAIChatService()
    }

    var runningTasks: [PlantAnalysisTask] {
        tasks.filter { $0.status.isRunning }
    }

    var completedTasks: [PlantAnalysisTask] {
        tasks.filter { $0.status == .completed || $0.status == .reported }
    }

    var failedTasks: [PlantAnalysisTask] {
        tasks.filter { $0.status == .failed }
    }

    func prepare(image: UIImage) {
        pendingImage = image
    }

    @discardableResult
    func enqueue(image: UIImage, draft: PlantReportDraft, farm: Farm) -> UUID {
        var reportDraft = draft
        reportDraft.image = image

        let task = PlantAnalysisTask(image: image, farm: farm, draft: reportDraft)
        tasks.insert(task, at: 0)
        start(taskID: task.id)
        HapticManager.selection()
        return task.id
    }

    func task(withID id: UUID) -> PlantAnalysisTask? {
        tasks.first { $0.id == id }
    }

    func retry(taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        runners[taskID]?.cancel()
        tasks[index].attempt += 1
        tasks[index].status = .queued
        tasks[index].stageTitle = "Menyiapkan ulang foto tanaman"
        tasks[index].progress = 0.05
        tasks[index].errorMessage = nil
        tasks[index].updatedAt = .now
        start(taskID: taskID)
    }

    func markReported(taskID: UUID) {
        update(taskID: taskID) { task in
            task.status = .reported
            task.stageTitle = "Laporan diterima koperasi"
            task.progress = 1
        }
        pendingImage = nil
        HapticManager.success()
    }

    func isResponding(in taskID: UUID) -> Bool {
        respondingChatTaskIDs.contains(taskID)
    }

    func sendChatMessage(_ text: String, taskID: UUID) async {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty,
              let index = tasks.firstIndex(where: { $0.id == taskID }),
              let diagnosis = tasks[index].diagnosis,
              !respondingChatTaskIDs.contains(taskID) else { return }

        tasks[index].chatMessages.append(PlantChatMessage(role: .farmer, text: message))
        respondingChatTaskIDs.insert(taskID)

        let response = await chatService.reply(to: message, diagnosis: diagnosis)

        guard let refreshedIndex = tasks.firstIndex(where: { $0.id == taskID }) else {
            respondingChatTaskIDs.remove(taskID)
            return
        }
        tasks[refreshedIndex].chatMessages.append(
            PlantChatMessage(role: .assistant, text: response)
        )
        tasks[refreshedIndex].updatedAt = .now
        respondingChatTaskIDs.remove(taskID)
        HapticManager.selection()
    }

    private func start(taskID: UUID) {
        runners[taskID] = Task { [weak self] in
            await self?.run(taskID: taskID)
        }
    }

    private func run(taskID: UUID) async {
        do {
            update(taskID: taskID) { task in
                task.status = .uploading
                task.stageTitle = "Mengunggah foto tanaman"
                task.progress = 0.22
            }
            try await Task.sleep(for: .milliseconds(650))

            update(taskID: taskID) { task in
                task.status = .analyzing
                task.stageTitle = "AI membaca pola gejala"
                task.progress = 0.52
            }
            try await Task.sleep(for: .milliseconds(700))

            guard let currentTask = task(withID: taskID) else { return }
            let request = PlantAnalysisRequest(
                title: currentTask.draft.title,
                description: currentTask.draft.description,
                category: currentTask.draft.category.rawValue,
                crop: currentTask.farm.crop,
                attempt: currentTask.attempt
            )
            let diagnosis = try await analysisService.analyze(request)

            update(taskID: taskID) { task in
                task.stageTitle = "Menyusun rekomendasi awal"
                task.progress = 0.84
            }
            try await Task.sleep(for: .milliseconds(550))

            update(taskID: taskID) { task in
                task.status = .completed
                task.stageTitle = "Analisis siap dilihat"
                task.progress = 1
                task.diagnosis = diagnosis
                if task.chatMessages.isEmpty {
                    task.chatMessages = [
                        PlantChatMessage(
                            role: .assistant,
                            text: "Saya sudah membaca hasil perkiraan \(diagnosis.prediction.lowercased()). Tanyakan langkah pemantauan yang aman sebelum laporan dikirim ke koperasi."
                        )
                    ]
                }
            }
            HapticManager.success()
        } catch is CancellationError {
            return
        } catch {
            update(taskID: taskID) { task in
                task.status = .failed
                task.stageTitle = "Analisis gagal"
                task.errorMessage = error.localizedDescription
            }
        }

        runners[taskID] = nil
    }

    private func update(taskID: UUID, mutation: (inout PlantAnalysisTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        mutation(&tasks[index])
        tasks[index].updatedAt = .now
    }
}
