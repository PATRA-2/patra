import Foundation
import Observation

@MainActor
@Observable
final class FarmStore {
    private(set) var farms: [Farm] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let service: FarmService

    init(service: FarmService) {
        self.service = service
    }

    var activeFarm: Farm? {
        farms.first { $0.isActive }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await refreshFromBackend()
            errorMessage = nil
        } catch {
            errorMessage = message(for: error)
        }
    }

    @discardableResult
    func addFarm(
        name: String,
        crop: String,
        location: String,
        coordinate: Coordinate
    ) async throws -> Farm {
        let created = try await service.create(FarmCreate(
            name: name,
            crop: crop,
            location: location,
            coordinate: coordinate,
            isActive: true
        ))
        try await refreshFromBackend()
        errorMessage = nil
        return farms.first { $0.id == created.id } ?? created
    }

    func setActiveFarm(id: Farm.ID) async throws {
        _ = try await service.update(id, FarmUpdate(
            name: nil,
            crop: nil,
            location: nil,
            coordinate: nil,
            isActive: true
        ))
        try await refreshFromBackend()
        errorMessage = nil
    }

    @discardableResult
    func updateFarm(
        id: Farm.ID,
        name: String,
        crop: String,
        location: String,
        coordinate: Coordinate,
        isActive: Bool
    ) async throws -> Farm {
        let updated = try await service.update(id, FarmUpdate(
            name: name,
            crop: crop,
            location: location,
            coordinate: coordinate,
            isActive: isActive
        ))
        try await refreshFromBackend()
        errorMessage = nil
        return farms.first { $0.id == updated.id } ?? updated
    }

    @discardableResult
    func deleteFarm(id: Farm.ID, force: Bool = false) async throws -> Farm? {
        let deleted = farms.first { $0.id == id }
        try await service.delete(id, force: force)
        try await refreshFromBackend()
        errorMessage = nil
        return deleted
    }

    private func refreshFromBackend() async throws {
        farms = try await service.farms(page: 1, pageSize: 100).items
    }

    private func message(for error: Error) -> String {
        (error as? APIError)?.userMessage ?? "Gagal memuat data lahan."
    }
}
