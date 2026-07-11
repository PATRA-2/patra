import CoreLocation
import Observation

@MainActor
@Observable
final class LocationManager {
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var coordinate: Coordinate?
    private(set) var isLocating = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let manager: CLLocationManager
    @ObservationIgnored private var serviceSession: CLServiceSession?
    @ObservationIgnored private var locationTask: Task<Void, Never>?

    init() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
    }

    var isAuthorizationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        authorizationStatus = manager.authorizationStatus
    }

    func requestCurrentLocation() {
        stopLocationRequest()
        authorizationStatus = manager.authorizationStatus
        errorMessage = nil

        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Layanan lokasi sedang nonaktif. Pilih pin lahan secara manual."
            return
        }

        guard !isAuthorizationDenied else {
            errorMessage = "Izin lokasi belum tersedia. Anda tetap dapat memilih pin secara manual."
            return
        }

        isLocating = true
        manager.requestWhenInUseAuthorization()
        serviceSession = CLServiceSession(authorization: .whenInUse)

        locationTask = Task { [weak self] in
            guard let self else { return }

            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if Task.isCancelled { return }

                    authorizationStatus = manager.authorizationStatus

                    if update.authorizationDenied || update.authorizationDeniedGlobally {
                        errorMessage = "Izin lokasi ditolak. Pilih pin manual atau aktifkan izin melalui Pengaturan."
                        stopLocationRequest()
                        return
                    }

                    if update.locationUnavailable {
                        continue
                    }

                    guard let location = update.location,
                          location.horizontalAccuracy >= 0,
                          location.horizontalAccuracy <= 250,
                          abs(location.timestamp.timeIntervalSinceNow) <= 60 else {
                        continue
                    }

                    coordinate = Coordinate(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    errorMessage = nil
                    stopLocationRequest()
                    return
                }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = "Lokasi belum dapat ditemukan. Coba lagi atau pilih pin secara manual."
                stopLocationRequest()
            }
        }
    }

    func stopLocationRequest() {
        locationTask?.cancel()
        locationTask = nil
        serviceSession = nil
        isLocating = false
        authorizationStatus = manager.authorizationStatus
    }
}
