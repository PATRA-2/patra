import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class AddFarmViewModel {
    var name = ""
    var crop = ""
    var location = ""
    var coordinate = Coordinate(latitude: 0, longitude: 0)
    var isActive = true
    var isLoading = false
    var errorMessage: String?
    var detectedLocationName = ""

    private let farmService: FarmService
    private let locationManager = CLLocationManager()

    init(env: AppEnvironment) {
        self.farmService = env.farms
        detectCurrentCoordinate()
    }

    func detectCurrentCoordinate() {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if let loc = locationManager.location {
                coordinate = Coordinate(latitude: loc.coordinate.latitude,
                                       longitude: loc.coordinate.longitude)
                detectedLocationName = String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude)
            }
        }
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func save() async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCrop = crop.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedCrop.isEmpty, !trimmedLocation.isEmpty else {
            errorMessage = "Nama, tanaman, dan lokasi wajib diisi."; return false
        }
        isLoading = true; defer { isLoading = false }
        do {
            _ = try await farmService.create(FarmCreate(
                name: trimmedName, crop: trimmedCrop, location: trimmedLocation,
                coordinate: coordinate, isActive: isActive))
            return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal menambah lahan."
            return false
        }
    }
}