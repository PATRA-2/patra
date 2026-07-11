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
    var searchText = ""
    var selectedLocationName = ""
    var selectedPlace: FarmPlaceResult?
    var selectedCoordinate: Coordinate?
    var selectedAddress = ""
    var validationMessage: String?
    var locationMessage: String?
    var searchActionMessage: String?
    var currentLocationActionMessage: String?
    var isSaving = false
    var isSuccess = false
    var savedFarm: Farm?
    var isReverseGeocoding = false
    var isRequestingCurrentLocation = false
    private(set) var suggestions: [MKLocalSearchCompletion] = []
    private(set) var isSearching = false
    private var searchErrorMessage: String?
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: defaultCoordinate.latitude, longitude: defaultCoordinate.longitude),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))

    @ObservationIgnored private let farmStore: FarmStore
    @ObservationIgnored private let searchService: FarmPlaceSearchService
    @ObservationIgnored private let placeResolver: any FarmPlaceResolving
    @ObservationIgnored private let locationManager: LocationManager
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var placeSearchTask: Task<Void, Never>?
    @ObservationIgnored private var reverseTask: Task<Void, Never>?
    @ObservationIgnored private var lookupToken = UUID()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

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

        self.suggestions = self.searchService.suggestions
        self.isSearching = self.searchService.isSearching
        self.searchErrorMessage = self.searchService.errorMessage

        self.searchService.$suggestions
            .sink { [weak self] suggestions in
                self?.suggestions = suggestions
            }
            .store(in: &cancellables)
        self.searchService.$isSearching
            .sink { [weak self] isSearching in
                self?.isSearching = isSearching
            }
            .store(in: &cancellables)
        self.searchService.$errorMessage
            .sink { [weak self] errorMessage in
                self?.searchErrorMessage = errorMessage
            }
            .store(in: &cancellables)
    }

    var cropChoices: [CropChoice] { CropChoice.allCases }
    var searchFeedbackMessage: String? { searchErrorMessage ?? searchActionMessage }
    var currentLocationErrorMessage: String? { locationManager.errorMessage ?? currentLocationActionMessage }
    var progressText: String { "Langkah \(step.rawValue) dari 3" }

    var finalCrop: String {
        guard let selectedCrop else { return "" }
        switch selectedCrop {
        case .other: return customCrop.trimmingCharacters(in: .whitespacesAndNewlines)
        default: return selectedCrop.rawValue
        }
    }

    var finalLocationName: String { selectedLocationName.trimmingCharacters(in: .whitespacesAndNewlines) }
    var markerTitle: String {
        if isReverseGeocoding { return "Mencari nama lokasi…" }
        return finalLocationName.isEmpty ? "Lokasi lahan" : finalLocationName
    }

    var coordinateText: String {
        guard let selectedCoordinate else { return "Koordinat belum dipilih" }
        return String(format: "%.5f, %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude)
    }

    var hasDraft: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedCrop != nil ||
        !customCrop.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
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
                validationMessage = "Pilih titik lahan dan pastikan nama lokasi berisi minimal tiga karakter."
                return
            }
            step = .confirmation
        case .confirmation:
            break
        }
        HapticManager.selection()
    }

    func goBack() -> Bool {
        guard !isSaving else { return true }

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
        searchText = text
        searchActionMessage = nil
        searchTask?.cancel()

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count >= 2 else {
            isSearching = false
            searchService.clearSuggestions()
            return
        }

        searchService.clearSuggestions()
        isSearching = true
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self?.searchService.updateQuery(text)
        }
    }

    func updateSearchRegion(_ region: MKCoordinateRegion) {
        searchService.updateRegion(region)
    }

    func clearSearch() {
        searchTask?.cancel()
        placeSearchTask?.cancel()
        searchText = ""
        isSearching = false
        searchActionMessage = nil
        searchService.clearSuggestions()
    }

    func clearSelectedLocation() {
        lookupToken = UUID()
        reverseTask?.cancel()
        placeSearchTask?.cancel()
        isReverseGeocoding = false
        selectedPlace = nil
        selectedCoordinate = nil
        selectedLocationName = ""
        selectedAddress = ""
        locationMessage = nil
    }

    func updateSelectedLocationName(_ text: String) {
        selectedLocationName = text
        if text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
            locationMessage = nil
            validationMessage = nil
        }
    }

    func selectSuggestion(_ completion: MKLocalSearchCompletion) {
        placeSearchTask?.cancel()
        lookupToken = UUID()
        let token = lookupToken
        reverseTask?.cancel()
        isReverseGeocoding = false
        searchActionMessage = nil
        validationMessage = nil
        placeSearchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await searchService.select(completion)
                guard !Task.isCancelled, token == lookupToken else { return }
                applyPlace(result)
            } catch is CancellationError {
                return
            } catch {
                guard token == lookupToken else { return }
                searchActionMessage = "Lokasi ini belum bisa dipilih. Coba hasil lain atau pilih titik di peta."
            }
        }
    }

    func selectCoordinate(_ coordinate: Coordinate) {
        lookupToken = UUID()
        let token = lookupToken
        searchTask?.cancel()
        placeSearchTask?.cancel()
        searchText = ""
        searchService.clearSuggestions()
        selectedCoordinate = coordinate
        selectedLocationName = ""
        selectedPlace = nil
        selectedAddress = ""
        currentLocationActionMessage = nil
        locationMessage = "Mencari nama lokasi..."
        validationMessage = nil
        isReverseGeocoding = true
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }

        reverseTask?.cancel()
        reverseTask = Task { [weak self] in
            await self?.resolveCoordinate(coordinate, token: token)
        }
    }

    func useCurrentLocation() {
        guard !isRequestingCurrentLocation else { return }

        currentLocationActionMessage = nil
        isRequestingCurrentLocation = true
        Task { [weak self] in
            guard let self else { return }
            defer { isRequestingCurrentLocation = false }
            do {
                let coordinate = try await locationManager.requestCurrentLocation()
                selectCoordinate(Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
            } catch {
                currentLocationActionMessage = "Lokasi belum bisa dideteksi. Pilih titik lahan secara manual di peta."
            }
        }
    }

    func save() async {
        guard canSave, let selectedCoordinate else {
            validationMessage = "Lengkapi data lahan sebelum menyimpan."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            savedFarm = try await farmStore.addFarm(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                crop: finalCrop,
                location: finalLocationName,
                coordinate: selectedCoordinate
            )
            isSuccess = true
            HapticManager.success()
        } catch {
            validationMessage = (error as? APIError)?.userMessage ?? "Lahan gagal disimpan ke server."
        }
    }

    private func resolveCoordinate(_ coordinate: Coordinate, token: UUID) async {
        do {
            let result = try await placeResolver.resolve(coordinate: coordinate)
            guard !Task.isCancelled, token == lookupToken else { return }
            isReverseGeocoding = false
            applyPlace(result)
        } catch is CancellationError {
            guard token == lookupToken else { return }
            isReverseGeocoding = false
        } catch {
            guard token == lookupToken else { return }
            isReverseGeocoding = false
            selectedCoordinate = coordinate
            locationMessage = "Nama lokasi belum ditemukan. Isi nama lokasi secara manual."
        }
    }

    private func applyPlace(_ result: FarmPlaceResult) {
        selectedPlace = result
        selectedCoordinate = result.coordinate
        selectedAddress = result.formattedAddress
        selectedLocationName = result.displayName
        searchText = ""
        locationMessage = nil
        validationMessage = nil
        searchService.clearSuggestions()
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: result.coordinate.latitude, longitude: result.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
}
