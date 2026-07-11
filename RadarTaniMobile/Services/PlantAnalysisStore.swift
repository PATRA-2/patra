import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PlantAnalysisStore {
    private(set) var tasks: [PlantAnalysisTask]
    private(set) var respondingChatTaskIDs: Set<UUID> = []
    var pendingImage: UIImage?

    @ObservationIgnored private var aiService: AIService?
    @ObservationIgnored private var reportService: ReportService?
    @ObservationIgnored private var runners: [UUID: Task<Void, Never>] = [:]

    init(tasks: [PlantAnalysisTask] = []) {
        self.tasks = tasks
    }

    func configure(aiService: AIService, reportService: ReportService) {
        self.aiService = aiService
        self.reportService = reportService
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

    func submitReport(taskID: UUID) async throws -> PlantReportOut {
        guard let service = reportService,
              let task = task(withID: taskID) else {
            throw APIError.unknown
        }

        let report = try await service.create(
            image: task.image,
            title: task.draft.title,
            category: task.draft.category.rawValue,
            description: task.draft.description.isEmpty ? nil : task.draft.description,
            farmId: task.farm.id,
            latitude: task.farm.coordinate.latitude,
            longitude: task.farm.coordinate.longitude,
            publishToFeed: true
        )
        update(taskID: taskID) { current in
            current.report = report
            current.diagnosis = report.diagnosis ?? current.diagnosis
            current.status = .reported
            current.stageTitle = report.status
            current.progress = 1
            current.errorMessage = nil
        }
        pendingImage = nil
        HapticManager.success()
        return report
    }

    func isResponding(in taskID: UUID) -> Bool {
        respondingChatTaskIDs.contains(taskID)
    }

    func sendChatMessage(_ text: String, taskID: UUID) async {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty,
              let service = aiService,
              let index = tasks.firstIndex(where: { $0.id == taskID }),
              let diagnosis = tasks[index].diagnosis,
              !respondingChatTaskIDs.contains(taskID) else { return }

        tasks[index].chatMessages.append(PlantChatMessage(role: .farmer, text: message))
        respondingChatTaskIDs.insert(taskID)

        let response: String
        do {
            response = try await service.chat(message: message, diagnosis: diagnosis)
        } catch {
            response = (error as? APIError)?.userMessage ?? "Jawaban AI belum dapat dimuat dari server."
        }

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
            guard let service = aiService,
                  let currentTask = task(withID: taskID) else {
                throw APIError.unknown
            }

            update(taskID: taskID) { task in
                task.status = .uploading
                task.stageTitle = "Mengunggah foto tanaman ke server"
                task.progress = 0.25
            }
            update(taskID: taskID) { task in
                task.status = .analyzing
                task.stageTitle = "AI backend membaca pola gejala"
                task.progress = 0.55
            }

            let diagnosis = try await service.diagnose(
                image: currentTask.image,
                crop: currentTask.farm.crop,
                symptomNotes: currentTask.draft.description.isEmpty
                    ? nil
                    : currentTask.draft.description
            )

            update(taskID: taskID) { task in
                task.status = .completed
                task.stageTitle = "Analisis backend siap dilihat"
                task.progress = 1
                task.diagnosis = diagnosis
                task.errorMessage = nil
                if task.chatMessages.isEmpty {
                    task.chatMessages = [
                        PlantChatMessage(
                            role: .assistant,
                            text: "Hasil analisis sudah diterima dari server. Tanyakan langkah pemantauan yang aman sebelum laporan dikirim ke koperasi."
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
                task.errorMessage = (error as? APIError)?.userMessage ?? error.localizedDescription
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
