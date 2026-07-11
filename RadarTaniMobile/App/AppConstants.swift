import Foundation

enum AppConstants {
    static let appName = "Radar Tani Desa"
}

enum AppConfig {
    static var apiBaseURL: URL {
        #if DEBUG
        URL(string: "http://127.0.0.1:8000/api/v1")!
        #else
        URL(string: "https://api.radar-tani.id/api/v1")!
        #endif
    }
}