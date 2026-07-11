import Foundation

enum PlantScanRoute: Hashable {
    case compose
    case processing(UUID)
    case tasks
    case result(UUID)
    case chat(UUID)
    case success(UUID)
}

struct PlantReportConfirmation: Identifiable {
    let id: UUID
}
