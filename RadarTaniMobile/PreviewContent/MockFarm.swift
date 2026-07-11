enum MockFarm {
    static let active = Farm(
        name: "Sawah Utara",
        crop: "Padi",
        location: "Desa Sukamaju",
        coordinate: Coordinate(latitude: -7.79560, longitude: 110.36950),
        isActive: true
    )

    static let samples = [
        active,
        Farm(
            name: "Kebun Barat",
            crop: "Cabai",
            location: "Dusun Karang",
            coordinate: Coordinate(latitude: -7.80210, longitude: 110.35520),
            isActive: false
        ),
        Farm(
            name: "Lahan Jagung",
            crop: "Jagung",
            location: "Blok Citarik",
            coordinate: Coordinate(latitude: -7.78370, longitude: 110.38230),
            isActive: false
        )
    ]
}
