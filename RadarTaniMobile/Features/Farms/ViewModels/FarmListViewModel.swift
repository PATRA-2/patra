import Observation

@MainActor
@Observable
final class FarmListViewModel {
    private let farmStore: FarmStore

    init(farmStore: FarmStore) {
        self.farmStore = farmStore
    }

    var farms: [Farm] { farmStore.farms }
    var activeFarm: Farm? { farmStore.activeFarm }

    func setActive(_ farm: Farm) {
        farmStore.setActiveFarm(id: farm.id)
        HapticManager.selection()
    }

    @discardableResult
    func delete(_ farm: Farm) -> Farm? {
        let deleted = farmStore.deleteFarm(id: farm.id)
        if deleted != nil { HapticManager.selection() }
        return deleted
    }
}
