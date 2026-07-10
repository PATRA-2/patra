import Observation

@MainActor
@Observable
final class RadarFeedViewModel {
    var selectedCategory: RadarReport.Category?
    var isRefreshing = false

    let activeFarmName = "Lahan Padi Timur"
    let feedRadius = "5 km"

    let reports: [RadarReport] = [
        RadarReport(category: .pest, distance: "1.2 km", title: "Waspada hawar daun pada padi", summary: "AI mendeteksi bercak cokelat dan daun menguning. Koperasi sudah memverifikasi laporan.", timeAgo: "2 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .seed, distance: "2.4 km", title: "Mencari bibit padi Inpari 32", summary: "Kelompok tani sekitar membutuhkan tambahan bibit untuk tanam ulang minggu ini.", timeAgo: "4 jam lalu", status: "Baru"),
        RadarReport(category: .labor, distance: "3.1 km", title: "Mencari tenaga panen", summary: "Dibutuhkan 6 pekerja untuk panen padi dua hari ke depan di blok sawah utara.", timeAgo: "5 jam lalu", status: "Aktif"),
        RadarReport(category: .seed, distance: "4.0 km", title: "Menawarkan bibit cabai", summary: "Koperasi Desa Sukamaju memiliki stok bibit cabai siap pindah tanam.", timeAgo: "7 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .pest, distance: "4.6 km", title: "Serangan trips pada cabai", summary: "Gejala daun mengeriting muncul di beberapa petak. Petani sekitar diminta memantau tanaman.", timeAgo: "10 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .labor, distance: "4.9 km", title: "Menawarkan tenaga kerja tanam", summary: "Tim kerja tani tersedia untuk olah tanah dan tanam padi mulai pekan depan.", timeAgo: "Kemarin", status: "Aktif")
    ]

    var filteredReports: [RadarReport] {
        guard let selectedCategory else { return reports }
        return reports.filter { $0.category == selectedCategory }
    }

    var selectedCategoryTitle: String {
        selectedCategory?.rawValue ?? "Semua Laporan"
    }

    func reportCount(for category: RadarReport.Category?) -> Int {
        guard let category else { return reports.count }
        return reports.filter { $0.category == category }.count
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        try? await Task.sleep(for: .milliseconds(500))
    }
}
