import Observation

@MainActor
@Observable
final class PlantScanViewModel {
    let activeFarm = Farm(name: "Sawah Utara", crop: "Padi", location: "Desa Sukamaju", isActive: true)
    let tips = [
        "Foto tanaman yang menunjukkan gejala tidak biasa.",
        "Ambil gambar daun atau batang dengan pencahayaan jelas.",
        "Hasil AI dapat dibagikan sebagai laporan ke Radar Feed."
    ]
}
