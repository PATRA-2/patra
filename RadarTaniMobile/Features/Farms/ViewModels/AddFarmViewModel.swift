import Observation

@MainActor
@Observable
final class AddFarmViewModel {
    var name = ""
    var crop = ""
    var location = ""
}
