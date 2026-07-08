import Observation

@MainActor
@Observable
final class RadarFeedViewModel {
    let reports: [RadarReport] = [
        RadarReport(category: .pest, distance: "1.2 km", title: "Tanaman Padi", summary: "Penyakit Hawar Daun", timeAgo: "2 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .pest, distance: "2.7 km", title: "Cabai", summary: "Serangan Trips", timeAgo: "5 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .pest, distance: "3.4 km", title: "Jagung", summary: "Ulat Grayak", timeAgo: "8 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .seed, distance: "4.6 km", title: "Padi", summary: "Kekurangan Air", timeAgo: "10 jam lalu", status: "Baru")
    ]
}
