import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class AddFarmViewModel {
    var name = ""
    var crop = ""
    var location = ""
    var coordinate = Coordinate(latitude: -7.7956, longitude: 110.3695)
    var isActive = true
    var isLoading = false
    var errorMessage: String?
    var detectedLocationName = ""

    private let farmService: FarmService
    private let locationManager = LocationManager()

    init(env: AppEnvironment) {
        self.farmService = env.farms
    }

    func detectCurrentLocation() {
        locationManager.requestLocation { [weak self] coord in
            Task { @MainActor in
                self?.coordinate = Coordinate(latitude: coord.latitude, longitude: coord.longitude)
                self?.detectedLocationName = String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
            }
        }
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