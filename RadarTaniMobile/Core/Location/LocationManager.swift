import CoreLocation
import Observation

extension Notification.Name {
    static let locationAuthorized = Notification.Name("locationAuthorized")
}

@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var isUpdating = false
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var singleCompletion: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func checkAuthorization() {
        let status = manager.authorizationStatus
        authorizationStatus = status
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdating()
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestSingleLocation() async throws -> CLLocationCoordinate2D {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw LocationError.denied
        }
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                if let loc = manager.location {
                    continuation.resume(returning: loc.coordinate)
                    self.locationContinuation = nil
                } else {
                    manager.requestLocation()
                }
            }
        }
    }

    func requestOneShot(completion: @escaping (CLLocationCoordinate2D) -> Void) {
        singleCompletion = completion
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if let loc = manager.location {
                completion(loc.coordinate)
                singleCompletion = nil
            } else {
                manager.requestLocation()
            }
        } else if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startUpdating() {
        isUpdating = true
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        isUpdating = false
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let coord = loc.coordinate
        Task { @MainActor in
            self.currentLocation = coord
            self.locationContinuation?.resume(returning: coord)
            self.locationContinuation = nil
            self.singleCompletion?(coord)
            self.singleCompletion = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: error)
            self.locationContinuation = nil
            self.singleCompletion = nil
        }
    }
}

enum LocationError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied: return "Akses lokasi ditolak. Buka Pengaturan untuk mengizinkan."
        case .unavailable: return "Lokasi tidak tersedia saat ini."
        }
    }
}