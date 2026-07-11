import Combine
import Foundation
import MapKit
import Observation
import SwiftUI

enum AddFarmStep: Int, CaseIterable {
    case information = 1
    case location = 2
    case confirmation = 3

    var title: String {
        switch self {
        case .information: "Informasi Lahan"
        case .location: "Tentukan Lokasi"
        case .confirmation: "Konfirmasi Lahan"
        }
    }
}

enum CropChoice: String, CaseIterable, Identifiable {
    case padi = "Padi"
    case cabai = "Cabai"
    case jagung = "Jagung"
    case tomat = "Tomat"
    case bawang = "Bawang"
    case other = "Lainnya"

    var id: String { rawValue }
}

@MainActor
@Observable
final class AddFarmViewModel {
    var step: AddFarmStep = .information
    var name = ""
    var selectedCrop: CropChoice?
    var customCrop = ""
    var locationQuery = ""
    var selectedPlace: FarmPlaceResult?
    var selectedCoordinate: Coordinate?
    var selectedAddress = ""
    var validationMessage: String?
    var locationMessage: String?
    var isSaving = false
    var isSuccess = false
    var savedFarm: Farm?
    var isReverseGeocoding = false
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: defaultCoordinate.latitude, longitude: defaultCoordinate.longitude),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))

    @ObservationIgnored private let farmStore: FarmStore
    @ObservationIgnored private let searchService: FarmPlaceSearchService
    @ObservationIgnored private let placeResolver: any FarmPlaceResolving
    @ObservationIgnored private let locationManager: LocationManager
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var reverseTask: Task<Void, Never>?
    @ObservationIgnored private var lookupToken = UUID()

    static let defaultCoordinate = Coordinate(latitude: -7.79560, longitude: 110.36950)
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: defaultCoordinate.latitude, longitude: defaultCoordinate.longitude),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    init(
        farmStore: FarmStore,
        searchService: FarmPlaceSearchService? = nil,
        placeResolver: (any FarmPlaceResolving)? = nil,
        locationManager: LocationManager? = nil
    ) {
        self.farmStore = farmStore
        self.searchService = searchService ?? FarmPlaceSearchService()
        self.placeResolver = placeResolver ?? MapKitFarmPlaceResolver()
        self.locationManager = locationManager ?? LocationManager()
    }

    var cropChoices: [CropChoice] { CropChoice.allCases }
    var suggestions: [MKLocalSearchCompletion] { searchService.suggestions }
    var isSearching: Bool { searchService.isSearching }
    var locationErrorMessage: String? { searchService.errorMessage ?? locationManager.errorMessage }
    var progressText: String { "Langkah \(step.rawValue) dari 3" }

    var finalCrop: String {
        guard let selectedCrop else { return "" }
        switch selectedCrop {
        case .other: return customCrop.trimmingCharacters(in: .whitespacesAndNewlines)
        default: return selectedCrop.rawValue
        }
    }

    var finalLocationName: String { locationQuery.trimmingCharacters(in: .whitespacesAndNewlines) }
    var markerTitle: String { finalLocationName.isEmpty ? "Lokasi lahan" : finalLocationName }

    var coordinateText: String {
        guard let selectedCoordinate else { return "Koordinat belum dipilih" }
        return String(format: "%.5f, %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude)
    }

    var hasDraft: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedCrop != nil ||
        !customCrop.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !locationQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedCoordinate != nil
    }

    var canContinueInformation: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && finalCrop.count >= 2
    }

    var canContinueLocation: Bool {
        selectedCoordinate != nil && finalLocationName.count >= 3 && !isReverseGeocoding
    }

    var canSave: Bool { canContinueInformation && canContinueLocation && !isSaving }

    func selectCrop(_ crop: CropChoice) {
        selectedCrop = crop
        validationMessage = nil
        HapticManager.selection()
    }

    func goForward() {
        validationMessage = nil
        switch step {
        case .information:
            guard canContinueInformation else {
                validationMessage = "Isi nama lahan dan pilih jenis tanaman dulu."
                return
            }
            step = .location
        case .location:
            guard canContinueLocation else {
                validationMessage = "Pilih titik lahan dan isi nama lokasi minimal tiga karakter."
                return
            }
            step = .confirmation
        case .confirmation:
            break
        }
        HapticManager.selection()
    }

    func goBack() -> Bool {
        switch step {
        case .information:
            return false
        case .location:
            step = .information
        case .confirmation:
            step = .location
        }
        HapticManager.selection()
        return true
    }

    func updateSearchText(_ text: String) {
        locationQuery = text
        selectedPlace = nil
        selectedAddress = ""
        locationMessage = nil
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.searchService.updateQuery(text)
        }
    }

    func updateSearchRegion(_ region: MKCoordinateRegion) {
        searchService.updateRegion(region)
    }

    func clearLocation() {
        lookupToken = UUID()
        reverseTask?.cancel()
        locationQuery = ""
        selectedPlace = nil
        selectedCoordinate = nil
        selectedAddress = ""
        locationMessage = nil
        searchService.clearSuggestions()
    }

    func selectSuggestion(_ completion: MKLocalSearchCompletion) {
        lookupToken = UUID()
        let token = lookupToken
        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await searchService.select(completion)
                guard token == lookupToken else { return }
                applyPlace(result)
            } catch {
                guard token == lookupToken else { return }
                locationMessage = "Saran lokasi belum bisa dipilih. Coba ketik manual atau pilih titik di peta."
            }
        }
    }

    func selectCoordinate(_ coordinate: Coordinate) {
        lookupToken = UUID()
        let token = lookupToken
        selectedCoordinate = coordinate
        selectedPlace = nil
        selectedAddress = ""
        locationMessage = "Mencari nama lokasi..."
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))

        reverseTask?.cancel()
        reverseTask = Task { [weak self] in
            await self?.resolveCoordinate(coordinate, token: token)
        }
    }

    func useCurrentLocation() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let coordinate = try await locationManager.requestCurrentLocation()
                selectCoordinate(Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
            } catch {
                locationMessage = "Lokasi belum bisa dideteksi. Pilih titik lahan secara manual di peta."
            }
        }
    }

    func save() async {
        guard canSave, let selectedCoordinate else {
            validationMessage = "Lengkapi data lahan sebelum menyimpan."
            return
        }

        isSaving = true
        try? await Task.sleep(for: .milliseconds(450))
        savedFarm = farmStore.addFarm(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            crop: finalCrop,
            location: finalLocationName,
            coordinate: selectedCoordinate
        )
        isSaving = false
        isSuccess = true
        HapticManager.success()
    }

    private func resolveCoordinate(_ coordinate: Coordinate, token: UUID) async {
        isReverseGeocoding = true
        defer { isReverseGeocoding = false }
        do {
            let result = try await placeResolver.resolve(coordinate: coordinate)
            guard token == lookupToken else { return }
            applyPlace(result)
        } catch {
            guard token == lookupToken else { return }
            selectedCoordinate = coordinate
            locationMessage = "Nama lokasi belum ditemukan. Isi nama lokasi secara manual."
        }
    }

    private func applyPlace(_ result: FarmPlaceResult) {
        selectedPlace = result
        selectedCoordinate = result.coordinate
        selectedAddress = result.formattedAddress
        locationQuery = result.displayName
        locationMessage = nil
        searchService.clearSuggestions()
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: result.coordinate.latitude, longitude: result.coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }
}
