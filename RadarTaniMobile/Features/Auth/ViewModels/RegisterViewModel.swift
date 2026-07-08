import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
}
