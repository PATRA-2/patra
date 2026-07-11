import Foundation

enum AppConstants {
    static let appName = "Radar Tani Desa"
}

enum AppConfig {
    static var apiBaseURL: URL {
        URL(string: "https://patra-api.kamil.my.id/api/v1")!
    }
}