import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class RadarMapViewModel {
    private(set) var reports: [MapReportOut] = []
    private(set) var activeFarm: Farm?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let feed: RadarFeedService
    private let farmStore: FarmStore

    let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.7956, longitude: 110.3695),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

    init(env: AppEnvironment) {
        self.feed = env.feed
        self.farmStore = env.farmStore
        self.activeFarm = env.farmStore.activeFarm
    }

    var preferredInitialRegion: MKCoordinateRegion {
        guard let activeFarm else { return initialRegion }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: activeFarm.coordinate.latitude,
                longitude: activeFarm.coordinate.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func loadActiveFarm() async {
        if farmStore.farms.isEmpty {
            await farmStore.load()
        }
        activeFarm = farmStore.activeFarm
    }

    func load(region: MKCoordinateRegion? = nil) async {
        isLoading = true; defer { isLoading = false }
        let minLat: Double? = region.map { $0.center.latitude - $0.span.latitudeDelta/2 }
        let maxLat: Double? = region.map { $0.center.latitude + $0.span.latitudeDelta/2 }
        let minLong: Double? = region.map { $0.center.longitude - $0.span.longitudeDelta/2 }
        let maxLong: Double? = region.map { $0.center.longitude + $0.span.longitudeDelta/2 }
        do {
            let items = try await feed.mapReports(minLat: minLat, maxLat: maxLat, minLong: minLong, maxLong: maxLong)
            reports = items.items
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat peta."
        }
    }

    func report(with id: MapReportOut.ID?) -> MapReportOut? {
        guard let id else { return reports.first }
        return reports.first { $0.id == id }
    }
}
