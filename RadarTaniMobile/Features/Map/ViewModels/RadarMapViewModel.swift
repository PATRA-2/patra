import CoreLocation
import MapKit
import Observation

struct RadarMapReport: Identifiable, Hashable {
    let id = UUID()
    let category: RadarReport.Category
    let title: String
    let summary: String
    let distance: String
    let status: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
@Observable
final class RadarMapViewModel {
    let initialRegion =
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -7.7956, longitude: 110.3695),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )

    let reports: [RadarMapReport] = [
        RadarMapReport(
            category: .pest,
            title: "Serangan hama pada padi",
            summary: "Daun menguning dan bercak cokelat terdeteksi di sawah timur.",
            distance: "2 KM",
            status: "Terverifikasi",
            latitude: -7.7898,
            longitude: 110.3651
        ),
        RadarMapReport(
            category: .seed,
            title: "Bibit padi tersedia",
            summary: "Koperasi menyiapkan bibit tambahan untuk musim tanam berikutnya.",
            distance: "4 KM",
            status: "Baru",
            latitude: -7.8092,
            longitude: 110.3897
        ),
        RadarMapReport(
            category: .labor,
            title: "Butuh bantuan panen",
            summary: "Kelompok tani mencari tenaga panen untuk akhir pekan.",
            distance: "6 KM",
            status: "Aktif",
            latitude: -7.7739,
            longitude: 110.3504
        )
    ]

    func report(with id: RadarMapReport.ID?) -> RadarMapReport? {
        guard let id else { return reports.first }
        return reports.first { $0.id == id }
    }
}
