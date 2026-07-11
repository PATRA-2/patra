import Observation

@MainActor
@Observable
final class FarmListViewModel {
    private let farmStore: FarmStore
    private(set) var actionErrorMessage: String?

    init(farmStore: FarmStore) {
        self.farmStore = farmStore
    }

    var farms: [Farm] { farmStore.farms }
    var activeFarm: Farm? { farmStore.activeFarm }
    var isLoading: Bool { farmStore.isLoading }
    var errorMessage: String? { actionErrorMessage ?? farmStore.errorMessage }

    func load() async {
        await farmStore.load()
    }

    func setActive(_ farm: Farm) async {
        do {
            try await farmStore.setActiveFarm(id: farm.id)
            actionErrorMessage = nil
            HapticManager.selection()
        } catch {
            actionErrorMessage = (error as? APIError)?.userMessage ?? "Lahan aktif gagal diperbarui di server."
        }
    }

    @discardableResult
    func delete(_ farm: Farm, force: Bool = false) async -> Bool {
        do {
            _ = try await farmStore.deleteFarm(id: farm.id, force: force)
            actionErrorMessage = nil
            HapticManager.selection()
            return true
        } catch {
            actionErrorMessage = (error as? APIError)?.userMessage ?? "Lahan gagal dihapus dari server."
            return false
        }
    }
}
