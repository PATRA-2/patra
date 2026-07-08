import Observation

@MainActor
@Observable
final class HomeViewModel {
    let activeFarm = Farm(name: "Sawah Utara", crop: "Padi", location: "Desa Sukamaju", isActive: true)
    let farmCount = 3
    let feedRadius = "5 KM"

    let latestReports: [RadarReport] = [
        RadarReport(category: .pest, distance: "2 KM", title: "Waspada gejala hama pada padi", summary: "Daun menguning dan bercak cokelat terdeteksi di sawah sekitar.", timeAgo: "1 jam lalu", status: "Terverifikasi"),
        RadarReport(category: .seed, distance: "4 KM", title: "Bibit padi tersedia minggu ini", summary: "Koperasi menyiapkan stok bibit tambahan untuk petani terdekat.", timeAgo: "3 jam lalu", status: "Baru")
    ]
}
