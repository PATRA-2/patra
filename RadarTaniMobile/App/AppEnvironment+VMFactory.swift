import Foundation

extension AppEnvironment {
    func makeLoginVM() -> LoginViewModel { .init(env: self) }
    func makeRegisterVM() -> RegisterViewModel { .init(env: self) }
    func makeHomeVM() -> HomeViewModel { .init(env: self) }
    func makeFarmListVM() -> FarmListViewModel { .init(farmStore: farmStore) }
    func makeAddFarmVM() -> AddFarmViewModel { .init(farmStore: farmStore) }
    func makePlantScanVM() -> PlantScanViewModel { .init(env: self, farmStore: farmStore) }
    func makeRadarFeedVM() -> RadarFeedViewModel { .init(env: self) }
    func makeReportDetailVM() -> ReportDetailViewModel { .init(env: self) }
    func makeRadarMapVM() -> RadarMapViewModel { .init(env: self) }
    func makeNotificationListVM() -> NotificationListViewModel { .init(env: self) }
    func makeProfileVM() -> ProfileViewModel { .init(env: self) }
    func makeOrderListVM() -> OrderListViewModel { .init(env: self) }
    func makeAIChatVM() -> PlantAIChatViewModel { .init(env: self) }
}
