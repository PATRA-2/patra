import Observation

@MainActor
@Observable
final class FarmListViewModel {
    let farms: [Farm] = [
        Farm(name: "Sawah Utara", crop: "Padi", location: "Desa Sukamaju", isActive: true),
        Farm(name: "Kebun Barat", crop: "Cabai", location: "Dusun Karang", isActive: false),
        Farm(name: "Lahan Jagung", crop: "Jagung", location: "Blok Citarik", isActive: false)
    ]
}
