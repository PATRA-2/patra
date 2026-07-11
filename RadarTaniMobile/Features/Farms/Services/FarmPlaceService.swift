import Combine
import CoreLocation
@preconcurrency import MapKit

struct FarmPlaceResult: Hashable, Sendable {
    let displayName: String
    let formattedAddress: String
    let coordinate: Coordinate
}

protocol FarmPlaceResolving: Sendable {
    func resolve(coordinate: Coordinate) async throws -> FarmPlaceResult
}

enum FarmPlaceError: LocalizedError {
    case noResult

    var errorDescription: String? {
        "Nama lokasi belum ditemukan. Koordinat tetap tersimpan dan nama lokasi dapat diisi manual."
    }
}

struct MapKitFarmPlaceResolver: FarmPlaceResolving {
    func resolve(coordinate: Coordinate) async throws -> FarmPlaceResult {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard let request = MKReverseGeocodingRequest(location: location) else {
            throw FarmPlaceError.noResult
        }
        request.preferredLocale = Locale(identifier: "id_ID")

        let mapItems = try await withTaskCancellationHandler {
            try await request.mapItems
        } onCancel: {
            request.cancel()
        }

        guard let mapItem = mapItems.first else {
            throw FarmPlaceError.noResult
        }
        return try FarmPlaceFormatter.result(from: mapItem)
    }
}

@MainActor
final class FarmPlaceSearchService: NSObject, ObservableObject {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.pointOfInterestFilter = .includingAll
    }

    func updateQuery(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil

        guard trimmedQuery.count >= 2 else {
            clearSuggestions()
            return
        }

        isSearching = true
        completer.queryFragment = trimmedQuery
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func clearSuggestions() {
        completer.queryFragment = ""
        suggestions = []
        isSearching = false
    }

    func select(_ completion: MKLocalSearchCompletion) async throws -> FarmPlaceResult {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = [.address, .pointOfInterest]
        let search = MKLocalSearch(request: request)

        let response = try await withTaskCancellationHandler {
            try await search.start()
        } onCancel: {
            search.cancel()
        }

        guard let mapItem = response.mapItems.first else {
            throw FarmPlaceError.noResult
        }
        return try FarmPlaceFormatter.result(from: mapItem)
    }
}

extension FarmPlaceSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(6))
        isSearching = false
        errorMessage = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        suggestions = []
        isSearching = false
        errorMessage = "Saran lokasi belum dapat dimuat. Coba lagi atau pilih titik pada peta."
    }
}

private enum FarmPlaceFormatter {
    static func result(from mapItem: MKMapItem) throws -> FarmPlaceResult {
        let coordinate = Coordinate(
            latitude: mapItem.location.coordinate.latitude,
            longitude: mapItem.location.coordinate.longitude
        )
        let representations = mapItem.addressRepresentations
        let address = representations?.fullAddress(
            includingRegion: true,
            singleLine: true
        ) ?? mapItem.address?.fullAddress ?? ""

        let candidates = [
            mapItem.name,
            representations?.cityName,
            representations?.cityWithContext,
            representations?.regionName
        ]
        let displayName = uniqueComponents(candidates).joined(separator: ", ").nilIfBlank
            ?? mapItem.address?.shortAddress
            ?? address.nilIfBlank

        guard let displayName else {
            throw FarmPlaceError.noResult
        }

        return FarmPlaceResult(
            displayName: displayName,
            formattedAddress: cleanedAddress(address, excluding: displayName),
            coordinate: coordinate
        )
    }

    private static func uniqueComponents(_ components: [String?]) -> [String] {
        var seen: Set<String> = []
        return components.compactMap { component in
            guard let value = component?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            let key = normalized(value)
            guard !seen.contains(where: { $0.contains(key) || key.contains($0) }) else { return nil }
            guard seen.insert(key).inserted else { return nil }
            return value
        }
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanedAddress(_ address: String, excluding displayName: String) -> String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.localizedCaseInsensitiveCompare(displayName).isOrderedSame else {
            return ""
        }
        return trimmed
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension ComparisonResult {
    var isOrderedSame: Bool { self == .orderedSame }
}
