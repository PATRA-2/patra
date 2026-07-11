import Foundation
import Observation

enum AddFarmStep: Int, Hashable {
    case information
    case location
    case confirmation
    case success

    var title: String {
        switch self {
        case .information: "Informasi Lahan"
        case .location: "Tentukan Lokasi"
        case .confirmation: "Konfirmasi Lahan"
        case .success: "Lahan Tersimpan"
        }
    }

    var progressIndex: Int {
        min(rawValue + 1, 3)
    }
}

enum FarmCropOption: String, CaseIterable, Identifiable {
    case rice = "Padi"
    case chili = "Cabai"
    case corn = "Jagung"
    case tomato = "Tomat"
    case onion = "Bawang"
    case other = "Lainnya"

    var id: String { rawValue }
}

@MainActor
@Observable
final class AddFarmViewModel {
    var step: AddFarmStep = .information
    var name = ""
    var selectedCrop: FarmCropOption = .rice
    var customCrop = ""
    var locationSearchText = ""
    var locationName = ""
    var detectedAddress = ""
    var coordinate: Coordinate?
    private(set) var isResolvingLocation = false
    private(set) var locationLookupError: String?
    private(set) var allowsManualLocationEntry = false
    private(set) var isSaving = false
    private(set) var savedFarm: Farm?

    @ObservationIgnored private let placeResolver: any FarmPlaceResolving
    @ObservationIgnored private var resolutionTask: Task<Void, Never>?

    init(placeResolver: (any FarmPlaceResolving)? = nil) {
        self.placeResolver = placeResolver ?? MapKitFarmPlaceResolver()
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var resolvedCrop: String {
        if selectedCrop == .other {
            return customCrop.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedCrop.rawValue
    }

    var trimmedLocationName: String {
        locationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canContinueInformation: Bool {
        trimmedName.count >= 3 && resolvedCrop.count >= 2
    }

    var canContinueLocation: Bool {
        trimmedLocationName.count >= 3 && coordinate != nil && !isResolvingLocation
    }

    var canPerformPrimaryAction: Bool {
        switch step {
        case .information: canContinueInformation
        case .location: canContinueLocation
        case .confirmation: canContinueInformation && canContinueLocation && !isSaving
        case .success: true
        }
    }

    var hasUnsavedChanges: Bool {
        !name.isEmpty
            || selectedCrop != .rice
            || !customCrop.isEmpty
            || !locationSearchText.isEmpty
            || !locationName.isEmpty
            || coordinate != nil
            || step != .information
    }

    func advance() {
        guard canPerformPrimaryAction else { return }

        switch step {
        case .information:
            name = trimmedName
            customCrop = customCrop.trimmingCharacters(in: .whitespacesAndNewlines)
            step = .location
        case .location:
            locationName = trimmedLocationName
            step = .confirmation
        case .confirmation, .success:
            break
        }
    }

    func moveToPreviousStep() -> Bool {
        switch step {
        case .location:
            step = .information
            return true
        case .confirmation:
            step = .location
            return true
        case .information, .success:
            return false
        }
    }

    func setCoordinate(_ coordinate: Coordinate) {
        self.coordinate = coordinate
    }

    func resolveLocation(at coordinate: Coordinate) {
        resolutionTask?.cancel()
        self.coordinate = coordinate
        locationName = ""
        locationSearchText = ""
        detectedAddress = ""
        locationLookupError = nil
        allowsManualLocationEntry = false
        isResolvingLocation = true

        resolutionTask = Task { [weak self, placeResolver] in
            do {
                let result = try await placeResolver.resolve(coordinate: coordinate)
                try Task.checkCancellation()
                guard let self, self.coordinate == coordinate else { return }
                self.applyPlaceResult(result)
            } catch is CancellationError {
                return
            } catch {
                guard let self, self.coordinate == coordinate else { return }
                self.isResolvingLocation = false
                self.locationLookupError = error.localizedDescription
                self.allowsManualLocationEntry = true
            }
        }
    }

    func applyPlaceResult(_ result: FarmPlaceResult) {
        resolutionTask?.cancel()
        coordinate = result.coordinate
        locationName = result.displayName
        locationSearchText = result.displayName
        detectedAddress = result.formattedAddress
        isResolvingLocation = false
        locationLookupError = nil
        allowsManualLocationEntry = false
    }

    func clearLocationSelection() {
        resolutionTask?.cancel()
        locationSearchText = ""
        locationName = ""
        detectedAddress = ""
        coordinate = nil
        isResolvingLocation = false
        locationLookupError = nil
        allowsManualLocationEntry = false
    }

    func updateLocationSearchText(_ text: String) {
        locationSearchText = text
        guard text.trimmingCharacters(in: .whitespacesAndNewlines) != locationName else { return }
        locationName = ""
        detectedAddress = ""
        locationLookupError = nil
        allowsManualLocationEntry = false
    }

    func enableManualLocationEntry(message: String? = nil) {
        resolutionTask?.cancel()
        isResolvingLocation = false
        locationLookupError = message ?? FarmPlaceError.noResult.localizedDescription
        allowsManualLocationEntry = true
        locationName = ""
    }

    func cancelLocationLookup() {
        resolutionTask?.cancel()
        isResolvingLocation = false
    }

    func save(to farmStore: FarmStore) async {
        guard canContinueInformation,
              canContinueLocation,
              let coordinate,
              !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await Task.sleep(for: .milliseconds(650))
        } catch {
            return
        }

        savedFarm = farmStore.addFarm(
            name: trimmedName,
            crop: resolvedCrop,
            location: trimmedLocationName,
            coordinate: coordinate
        )
        step = .success
    }
}
