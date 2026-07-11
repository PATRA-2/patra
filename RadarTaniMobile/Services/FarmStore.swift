import Observation

@MainActor
@Observable
final class FarmStore {
    private(set) var farms: [Farm]

    init(farms: [Farm]? = nil) {
        self.farms = farms ?? MockFarm.samples
        normalizeActiveFarm()
    }

    var activeFarm: Farm? {
        farms.first { $0.isActive }
    }

    @discardableResult
    func addFarm(
        name: String,
        crop: String,
        location: String,
        coordinate: Coordinate
    ) -> Farm {
        for index in farms.indices {
            farms[index].isActive = false
        }

        let farm = Farm(
            name: name,
            crop: crop,
            location: location,
            coordinate: coordinate,
            isActive: true
        )
        farms.insert(farm, at: 0)
        return farm
    }

    func setActiveFarm(id: Farm.ID) {
        guard farms.contains(where: { $0.id == id }) else { return }

        for index in farms.indices {
            farms[index].isActive = farms[index].id == id
        }
    }

    @discardableResult
    func deleteFarm(id: Farm.ID) -> Farm? {
        guard let index = farms.firstIndex(where: { $0.id == id }) else { return nil }

        let deletedFarm = farms.remove(at: index)
        normalizeActiveFarm()
        return deletedFarm
    }

    private func normalizeActiveFarm() {
        guard !farms.isEmpty else { return }

        let activeID = farms.first { $0.isActive }?.id ?? farms[0].id
        for index in farms.indices {
            farms[index].isActive = farms[index].id == activeID
        }
    }
}
