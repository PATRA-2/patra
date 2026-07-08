import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let name = "Petani RTD"
    let cooperative = "Koperasi Desa Sukamaju"
    var notificationsEnabled = true
}
