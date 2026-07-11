# In-Memory Add Farm Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the native SwiftUI `Tambah Lahan` wizard, local farm deletion, and active farm sharing for `Lahan` and `Lapor` using one in-memory app-scoped `FarmStore`.

**Architecture:** Add `FarmStore` to `AppEnvironment` as `farmStore` while leaving existing backend `FarmService` as `farms`. Refactor farm list/add/report surfaces to consume `farmStore`, use a focused `AddFarmViewModel` for wizard state, and use MapKit services for search and reverse geocoding. Keep API contracts and backend services unchanged.

**Tech Stack:** SwiftUI Observation, MapKit, Core Location, Swift concurrency, Radar Tani design system, generated Info.plist keys in `RadarTaniMobile.xcodeproj/project.pbxproj`.

## Global Constraints

- Keep `HomeView.swift`, backend endpoints, and API contracts unchanged.
- Persist state only for the current app session.
- New farms always become active.
- Deletion is local-only with confirmation.
- Location is one point coordinate, not a polygon or acreage.
- Search and geocoding may require network access; manual fallback remains available.
- Use `safeAreaInset` for primary CTAs.
- Add `NSLocationWhenInUseUsageDescription` through generated Info.plist build settings.
- Do not commit unless the user explicitly asks for a commit.

---

## File Structure

- Modify `RadarTaniMobile/App/AppEnvironment.swift`: add app-scoped `let farmStore: FarmStore`.
- Modify `RadarTaniMobile/App/AppEnvironment+VMFactory.swift`: pass `FarmStore` into farm, add-farm, and plant-scan view models.
- Modify `RadarTaniMobile/Services/FarmStore.swift`: keep the in-memory source of truth and local delete behavior.
- Modify `RadarTaniMobile/Core/Location/LocationManager.swift`: expose one-shot loading, coordinate, authorization, and friendly error state.
- Modify `RadarTaniMobile/Features/Farms/Services/FarmPlaceService.swift`: keep MapKit search and reverse-geocode service boundary.
- Replace `RadarTaniMobile/Features/Farms/Components/FarmMapPickerView.swift`: SwiftUI `MapReader` picker with marker and tap callback.
- Replace `RadarTaniMobile/Features/Farms/ViewModels/AddFarmViewModel.swift`: wizard state, validation, search debounce, stale lookup cancellation, GPS, save, success actions.
- Replace `RadarTaniMobile/Features/Farms/Views/AddFarmView.swift`: three-step wizard UI with success state.
- Modify `RadarTaniMobile/Features/Farms/ViewModels/FarmListViewModel.swift`: store-backed list and deletion.
- Modify `RadarTaniMobile/Features/Farms/Views/FarmListView.swift`: store-backed card list, navigation push to add flow, local delete confirmation, tab binding.
- Modify `RadarTaniMobile/Features/Home/Views/MainTabView.swift`: pass `$selectedTab` into `FarmListView`.
- Modify `RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift`: use `FarmStore.activeFarm` instead of backend farm fetch.
- Modify `RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift`: accept the selected-tab binding, refresh active farm from the store when the tab appears, and route missing-farm users to the `Lahan` tab.
- Modify `RadarTaniMobile.xcodeproj/project.pbxproj`: add location usage description in Debug and Release build settings.

---

### Task 1: Wire App-Scoped FarmStore

**Files:**
- Modify: `RadarTaniMobile/App/AppEnvironment.swift`
- Modify: `RadarTaniMobile/App/AppEnvironment+VMFactory.swift`
- Modify: `RadarTaniMobile/Services/FarmStore.swift`
- Modify: `RadarTaniMobile/Features/Farms/ViewModels/FarmListViewModel.swift`
- Modify: `RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift`

**Interfaces:**
- Consumes: existing `Farm`, `MockFarm.samples`, `AppEnvironment`.
- Produces: `AppEnvironment.farmStore: FarmStore`, `FarmListViewModel.delete(_:)`, `PlantScanViewModel.refreshActiveFarm()`.

- [ ] **Step 1: Add `FarmStore` to `AppEnvironment`**

In `RadarTaniMobile/App/AppEnvironment.swift`, add:

```swift
let farmStore: FarmStore
```

Initialize it in `init(baseURL:)`:

```swift
self.farmStore = FarmStore()
```

Keep the existing backend `let farms: FarmService` unchanged.

- [ ] **Step 2: Confirm local delete invariant in `FarmStore`**

Keep `RadarTaniMobile/Services/FarmStore.swift` shaped like this:

```swift
@MainActor
@Observable
final class FarmStore {
    private(set) var farms: [Farm]

    init(farms: [Farm]? = nil) {
        self.farms = farms ?? MockFarm.samples
        normalizeActiveFarm()
    }

    var activeFarm: Farm? {
        farms.first { $0.isActive }
    }

    @discardableResult
    func addFarm(name: String, crop: String, location: String, coordinate: Coordinate) -> Farm {
        for index in farms.indices { farms[index].isActive = false }
        let farm = Farm(name: name, crop: crop, location: location, coordinate: coordinate, isActive: true)
        farms.insert(farm, at: 0)
        return farm
    }

    func setActiveFarm(id: Farm.ID) {
        guard farms.contains(where: { $0.id == id }) else { return }
        for index in farms.indices { farms[index].isActive = farms[index].id == id }
    }

    @discardableResult
    func deleteFarm(id: Farm.ID) -> Farm? {
        guard let index = farms.firstIndex(where: { $0.id == id }) else { return nil }
        let deletedFarm = farms.remove(at: index)
        normalizeActiveFarm()
        return deletedFarm
    }

    private func normalizeActiveFarm() {
        guard !farms.isEmpty else { return }
        let activeID = farms.first { $0.isActive }?.id ?? farms[0].id
        for index in farms.indices { farms[index].isActive = farms[index].id == activeID }
    }
}
```

- [ ] **Step 3: Replace `FarmListViewModel` with store-backed implementation**

In `RadarTaniMobile/Features/Farms/ViewModels/FarmListViewModel.swift`, use:

```swift
import Observation

@MainActor
@Observable
final class FarmListViewModel {
    private let farmStore: FarmStore

    init(farmStore: FarmStore) {
        self.farmStore = farmStore
    }

    var farms: [Farm] { farmStore.farms }
    var activeFarm: Farm? { farmStore.activeFarm }

    func setActive(_ farm: Farm) {
        farmStore.setActiveFarm(id: farm.id)
        HapticManager.selection()
    }

    @discardableResult
    func delete(_ farm: Farm) -> Farm? {
        let deleted = farmStore.deleteFarm(id: farm.id)
        if deleted != nil { HapticManager.selection() }
        return deleted
    }
}
```

- [ ] **Step 4: Update view model factories**

In `RadarTaniMobile/App/AppEnvironment+VMFactory.swift`, update these factories:

```swift
func makeFarmListVM() -> FarmListViewModel { .init(farmStore: farmStore) }
func makeAddFarmVM() -> AddFarmViewModel { .init(farmStore: farmStore) }
func makePlantScanVM() -> PlantScanViewModel { .init(env: self, farmStore: farmStore) }
```

- [ ] **Step 5: Refactor `PlantScanViewModel` active farm source**

In `RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift`, remove `private let farmService: FarmService` and add:

```swift
private let farmStore: FarmStore
```

Update the initializer:

```swift
init(env: AppEnvironment, farmStore: FarmStore) {
    self.reportService = env.reports
    self.farmStore = farmStore
}
```

Replace active farm loading with:

```swift
func loadActiveFarm() async {
    activeFarm = farmStore.activeFarm
}

func refreshActiveFarm() {
    activeFarm = farmStore.activeFarm
}
```

- [ ] **Step 6: Build-check task 1**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Expected: build may still fail if later tasks have not updated `AddFarmViewModel` initializer usage. Fix unrelated compile errors before continuing.

---

### Task 2: Implement Location Services And Map Picker

**Files:**
- Modify: `RadarTaniMobile/Core/Location/LocationManager.swift`
- Modify: `RadarTaniMobile/Features/Farms/Services/FarmPlaceService.swift`
- Replace: `RadarTaniMobile/Features/Farms/Components/FarmMapPickerView.swift`
- Modify: `RadarTaniMobile.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `Coordinate`, `FarmPlaceResult`.
- Produces: `LocationManager.requestCurrentLocation() async -> CLLocationCoordinate2D`, `FarmMapPickerView(coordinate:markerTitle:cameraPosition:onCoordinateSelected:onRegionChanged:)`.

- [ ] **Step 1: Add location usage description**

In both Debug and Release build settings blocks in `RadarTaniMobile.xcodeproj/project.pbxproj`, add near the existing usage descriptions:

```text
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Lokasi digunakan untuk membantu memilih titik lahan Anda di peta.";
```

- [ ] **Step 2: Add async one-shot location API**

In `RadarTaniMobile/Core/Location/LocationManager.swift`, add state:

```swift
private(set) var errorMessage: String?
private(set) var oneShotCoordinate: CLLocationCoordinate2D?
```

Add this method and keep existing delegate wiring:

```swift
func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
    errorMessage = nil
    let status = manager.authorizationStatus
    authorizationStatus = status

    if status == .denied || status == .restricted {
        errorMessage = "Akses lokasi belum aktif. Anda tetap bisa memilih titik lahan langsung di peta."
        throw LocationError.denied
    }

    if status == .notDetermined {
        manager.requestWhenInUseAuthorization()
    }

    isUpdating = true
    return try await withCheckedThrowingContinuation { continuation in
        self.locationContinuation = continuation
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
```

In `didUpdateLocations`, set `isUpdating = false`, `currentLocation`, `oneShotCoordinate`, and resume the continuation. In `didFailWithError`, set `isUpdating = false`, a friendly error message, and resume the continuation with the error.

- [ ] **Step 3: Keep MapKit search service boundary**

Ensure `RadarTaniMobile/Features/Farms/Services/FarmPlaceService.swift` keeps these public types and methods:

```swift
struct FarmPlaceResult: Hashable, Sendable {
    let displayName: String
    let formattedAddress: String
    let coordinate: Coordinate
}

protocol FarmPlaceResolving: Sendable {
    func resolve(coordinate: Coordinate) async throws -> FarmPlaceResult
}

@MainActor
final class FarmPlaceSearchService: NSObject, ObservableObject {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errorMessage: String?

    func updateQuery(_ query: String)
    func updateRegion(_ region: MKCoordinateRegion)
    func clearSuggestions()
    func select(_ completion: MKLocalSearchCompletion) async throws -> FarmPlaceResult
}
```

Use `MKLocalSearch.Request(completion:)` for completion selection and `MKReverseGeocodingRequest(location:)` for coordinate lookup.

- [ ] **Step 4: Replace temporary map picker**

Replace `RadarTaniMobile/Features/Farms/Components/FarmMapPickerView.swift` with:

```swift
import MapKit
import SwiftUI

struct FarmMapPickerView: View {
    let coordinate: Coordinate?
    let markerTitle: String
    @Binding var cameraPosition: MapCameraPosition
    let onCoordinateSelected: (Coordinate) -> Void
    let onRegionChanged: (MKCoordinateRegion) -> Void

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let coordinate {
                    Marker(markerTitle, coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
                        .tint(RTDColor.deepGreen)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onTapGesture { point in
                guard let coordinate = proxy.convert(point, from: .local) else { return }
                onCoordinateSelected(Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                onRegionChanged(context.region)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .accessibilityLabel("Peta lokasi lahan")
        .accessibilityHint("Ketuk peta untuk memindahkan pin lahan")
    }
}
```

- [ ] **Step 5: Build-check task 2**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Expected: build may still fail because `AddFarmView` has not yet been replaced. Fix MapKit, Core Location, or project setting errors before continuing.

---

### Task 3: Implement AddFarmViewModel Wizard Logic

**Files:**
- Replace: `RadarTaniMobile/Features/Farms/ViewModels/AddFarmViewModel.swift`

**Interfaces:**
- Consumes: `FarmStore`, `FarmPlaceSearchService`, `FarmPlaceResolving`, `LocationManager`, `FarmPlaceResult`, `Coordinate`.
- Produces: `AddFarmStep`, `CropChoice`, `goForward()`, `goBack()`, `selectCrop(_:)`, `updateSearchText(_:)`, `selectSuggestion(_:)`, `selectCoordinate(_:)`, `useCurrentLocation()`, `save()`.

- [ ] **Step 1: Define wizard enums**

At the top of `AddFarmViewModel.swift`, use:

```swift
import Combine
import Foundation
import MapKit
import Observation

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
```

- [ ] **Step 2: Replace the view model state**

Use this class skeleton:

```swift
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
    var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)

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
        searchService: FarmPlaceSearchService = FarmPlaceSearchService(),
        placeResolver: any FarmPlaceResolving = MapKitFarmPlaceResolver(),
        locationManager: LocationManager = LocationManager()
    ) {
        self.farmStore = farmStore
        self.searchService = searchService
        self.placeResolver = placeResolver
        self.locationManager = locationManager
    }
}
```

- [ ] **Step 3: Add computed validation and display state**

Inside the class, add:

```swift
var cropChoices: [CropChoice] { CropChoice.allCases }
var suggestions: [MKLocalSearchCompletion] { searchService.suggestions }
var isSearching: Bool { searchService.isSearching }
var locationErrorMessage: String? { searchService.errorMessage ?? locationManager.errorMessage }
var progressText: String { "Langkah \(step.rawValue) dari 3" }

var finalCrop: String {
    guard let selectedCrop else { return "" }
    switch selectedCrop {
    case .other: customCrop.trimmingCharacters(in: .whitespacesAndNewlines)
    default: selectedCrop.rawValue
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
```

- [ ] **Step 4: Add navigation, search, coordinate, GPS, and save actions**

Add these methods inside the class:

```swift
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
        await self?.searchService.updateQuery(text)
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
```

- [ ] **Step 5: Add private place helpers**

Add these private methods inside the class:

```swift
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
```

- [ ] **Step 6: Build-check task 3**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Expected: build may still fail because `AddFarmView` still uses old properties such as `crop`, `location`, and `coordinate`. Fix only errors inside `AddFarmViewModel` before continuing.

---

### Task 4: Replace AddFarmView With Three-Step Wizard

**Files:**
- Replace: `RadarTaniMobile/Features/Farms/Views/AddFarmView.swift`

**Interfaces:**
- Consumes: `AddFarmViewModel`, `FarmMapPickerView`, `MainTab` binding, `dismiss`.
- Produces: `AddFarmView(selectedTab:)`, success actions for `Lihat Lahan` and `Mulai Lapor`.

- [ ] **Step 1: Change `AddFarmView` initializer and state**

Replace the top of `AddFarmView.swift` with:

```swift
import MapKit
import SwiftUI

struct AddFarmView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: MainTab
    @State private var viewModel: AddFarmViewModel?
    @State private var showDiscardAlert = false

    init(selectedTab: Binding<MainTab>) {
        self._selectedTab = selectedTab
    }
```

- [ ] **Step 2: Implement body, navigation, and CTA shell**

Use this body shape:

```swift
var body: some View {
    Group {
        if let viewModel {
            content(viewModel)
        } else {
            RTDLoadingView()
        }
    }
    .background(RTDColor.background)
    .navigationTitle(viewModel?.isSuccess == true ? "Lahan Tersimpan" : viewModel?.step.title ?? "Tambah Lahan")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
        ToolbarItem(placement: .topBarLeading) {
            Button(viewModel?.step == .information ? "Batal" : "Kembali") {
                handleBack()
            }
        }
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
        if let viewModel, !viewModel.isSuccess { bottomCTA(viewModel) }
    }
    .alert("Buang perubahan?", isPresented: $showDiscardAlert) {
        Button("Buang", role: .destructive) { dismiss() }
        Button("Lanjut Edit", role: .cancel) {}
    } message: {
        Text("Data lahan yang sudah diisi akan hilang.")
    }
    .task { if viewModel == nil { viewModel = env.makeAddFarmVM() } }
}
```

- [ ] **Step 3: Add step content switch**

Add:

```swift
@ViewBuilder
private func content(_ viewModel: AddFarmViewModel) -> some View {
    if viewModel.isSuccess {
        successView(viewModel)
    } else {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(viewModel.progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.deepGreen)
                    .accessibilityLabel(viewModel.progressText)

                switch viewModel.step {
                case .information: informationStep(viewModel)
                case .location: locationStep(viewModel)
                case .confirmation: confirmationStep(viewModel)
                }
            }
            .padding(20)
            .padding(.bottom, 96)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
```

- [ ] **Step 4: Add information step UI**

Add an `informationStep(_:)` with a `TextField("Nama lahan", text: Bindable(viewModel).name)`, crop chips for `viewModel.cropChoices`, a conditional custom crop `TextField("Jenis tanaman", text: Bindable(viewModel).customCrop)`, inline validation message, and an info card saying the new farm will become active. Use `RTDColor.cardBackground`, `.rtdCard()`, `.font(.headline/.body/.callout)`, and VoiceOver labels on icon-only elements.

- [ ] **Step 5: Add location step UI**

Add a `locationStep(_:)` that contains:

```swift
TextField("Cari nama tempat, desa, atau daerah", text: Binding(
    get: { viewModel.locationQuery },
    set: { viewModel.updateSearchText($0) }
))
```

Add a clear button when `locationQuery` is not empty that calls `viewModel.clearLocation()`. Render `viewModel.suggestions` as buttons showing `completion.title` and `completion.subtitle`, and call `viewModel.selectSuggestion(completion)`. Add `FarmMapPickerView` with `coordinate`, `markerTitle`, `$viewModel.cameraPosition`, `selectCoordinate`, and `updateSearchRegion`. Add `Gunakan Lokasi Saya`, `Mencari nama lokasi...`, error messages, selected-location card, and five-decimal coordinate text.

- [ ] **Step 6: Add confirmation and success UI**

Add `confirmationStep(_:)` showing name, crop, location, address, coordinate text, compact `FarmMapPickerView` with no-op callbacks, and a warning that the previous active farm will be deactivated.

Add `successView(_:)` with a success icon, saved farm name, and two buttons:

```swift
Button("Lihat Lahan") { dismiss() }
Button("Mulai Lapor") {
    selectedTab = .report
    dismiss()
}
```

- [ ] **Step 7: Add CTA and back handlers**

Add:

```swift
private func bottomCTA(_ viewModel: AddFarmViewModel) -> some View {
    VStack(spacing: 10) {
        if let message = viewModel.validationMessage {
            Text(message).font(.footnote).foregroundStyle(RTDColor.warningRed)
        }
        Button {
            if viewModel.step == .confirmation {
                Task { await viewModel.save() }
            } else {
                viewModel.goForward()
            }
        } label: {
            if viewModel.isSaving { ProgressView() } else { Text(viewModel.step == .confirmation ? "Simpan Lahan" : "Lanjut") }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.step == .information ? !viewModel.canContinueInformation : viewModel.step == .location ? !viewModel.canContinueLocation : !viewModel.canSave)
    }
    .padding(20)
    .background(.ultraThinMaterial)
}

private func handleBack() {
    guard let viewModel else { dismiss(); return }
    if viewModel.goBack() { return }
    if viewModel.hasDraft { showDiscardAlert = true } else { dismiss() }
}
```

- [ ] **Step 8: Build-check task 4**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Expected: compile errors should now be limited to callers using old `AddFarmView()` initializer. Fix all errors inside `AddFarmView.swift` before continuing.

---

### Task 5: Refactor Farm List, Tab Navigation, And Plant Scan Integration

**Files:**
- Modify: `RadarTaniMobile/Features/Farms/Views/FarmListView.swift`
- Modify: `RadarTaniMobile/Features/Home/Views/MainTabView.swift`
- Modify: `RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift`

**Interfaces:**
- Consumes: `FarmListViewModel`, `AddFarmView(selectedTab:)`, `PlantScanViewModel.refreshActiveFarm()`.
- Produces: navigation push add flow, local delete alert, tab switching to `Lapor`, and missing-farm routing from `Lapor` to `Lahan`.

- [ ] **Step 1: Change `MainTabView` farm tab binding**

In `RadarTaniMobile/Features/Home/Views/MainTabView.swift`, replace:

```swift
FarmListView()
```

with:

```swift
FarmListView(selectedTab: $selectedTab)
```

Also replace:

```swift
PlantScanView()
```

with:

```swift
PlantScanView(selectedTab: $selectedTab)
```

- [ ] **Step 2: Replace `FarmListView` sheet/API delete with navigation and store delete**

In `RadarTaniMobile/Features/Farms/Views/FarmListView.swift`, change the view header to:

```swift
struct FarmListView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedTab: MainTab
    @State private var viewModel: FarmListViewModel?
    @State private var deleteConfirmation: DeleteConfirmation?

    struct DeleteConfirmation: Identifiable {
        let id = UUID()
        let farm: Farm
    }
```

Remove `showAddFarm`, `showForceDeleteAlert`, `pendingForceDelete`, `.sheet`, `refreshable`, and backend delete helpers.

- [ ] **Step 3: Add list content and add navigation**

Use a `List` or `ScrollView` that reads `viewModel.farms`. The add toolbar should be:

```swift
ToolbarItem(placement: .topBarTrailing) {
    NavigationLink {
        AddFarmView(selectedTab: $selectedTab)
    } label: {
        Image(systemName: "plus")
            .font(.title3)
    }
    .accessibilityLabel("Tambah Lahan")
}
```

Each row keeps a `NavigationLink` to `FarmDetailView(farm:)`, supports swipe delete, and optionally includes an active button that calls `viewModel.setActive(farm)`.

- [ ] **Step 4: Add local delete confirmation**

Use this alert:

```swift
.alert("Hapus Lahan?", isPresented: .init(
    get: { deleteConfirmation != nil },
    set: { if !$0 { deleteConfirmation = nil } }
)) {
    if let farm = deleteConfirmation?.farm {
        Button("Hapus", role: .destructive) {
            _ = viewModel?.delete(farm)
            deleteConfirmation = nil
        }
        Button("Batal", role: .cancel) { deleteConfirmation = nil }
    }
} message: {
    if let farm = deleteConfirmation?.farm {
        Text("Lahan '\(farm.name)' akan dihapus dari daftar di perangkat ini.")
    }
}
```

- [ ] **Step 5: Pass tab binding into PlantScanView and refresh active farm on appear**

In `RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift`, change the header to:

```swift
struct PlantScanView: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var selectedTab: MainTab
    @State private var viewModel: PlantScanViewModel?
    @State private var path: [PlantScanRoute] = []
    @State private var analysisStore = PlantAnalysisStore()
```

Add this initializer:

```swift
init(selectedTab: Binding<MainTab>) {
    self._selectedTab = selectedTab
}
```

Keep `PlantScanView` owning its view model, but add an `.onAppear` after the existing `.task` that calls:

```swift
viewModel?.refreshActiveFarm()
```

Remove `@State private var showAddFarm = false` and the old `.sheet(isPresented: $showAddFarm)` that creates `AddFarmView()`. In `missingFarmCard`, replace the button action with:

```swift
selectedTab = .farms
```

Keep the button label as `Tambah Lahan`.

- [ ] **Step 6: Build-check task 5**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Expected: build succeeds or reports only preview initializer errors. Fix all compile errors before continuing.

---

### Task 6: Final Verification And Polish

**Files:**
- Modify only files already touched if verification finds issues.

**Interfaces:**
- Consumes: completed Tasks 1-5.
- Produces: verified build and clean diff whitespace.

- [ ] **Step 1: Run whitespace verification**

Run:

```bash
git diff --check
```

Expected: no output. Fix any reported whitespace errors.

- [ ] **Step 2: Run simulator build**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Manual behavior checklist**

In the simulator, verify:

```text
Tambah Lahan opens step 1 through navigation push.
Empty required fields keep Lanjut disabled.
Each crop choice works; Lainnya requires manual crop text.
Location search suggestions render and selection moves pin/camera.
Map tap moves pin and starts reverse geocoding.
Gunakan Lokasi Saya requests permission and uses the simulator coordinate.
Reverse-geocode failure keeps coordinate and allows manual location text.
Confirmation shows name, crop, location, address, and five-decimal coordinates.
Simpan Lahan inserts the farm at the top and makes it the only active farm.
Lihat Lahan returns to the list.
Mulai Lapor switches to the Lapor tab and shows the new active farm.
Deleting a non-active farm removes only that farm.
Deleting the active farm makes the first remaining farm active.
Deleting the last farm leaves Lapor in the missing-farm state.
Back from step 2/3 preserves draft values.
Cancel from step 1 with draft shows discard confirmation.
Keyboard does not cover the primary CTA.
VoiceOver labels for add, map, GPS, clear location, and delete are understandable.
```

- [ ] **Step 4: Inspect final diff**

Run:

```bash
git diff --stat
git diff -- docs/superpowers/specs/2026-07-11-in-memory-add-farm-flow-design.md docs/superpowers/plans/2026-07-11-in-memory-add-farm-flow.md
git diff -- RadarTaniMobile
```

Expected: diff only includes approved spec/plan and the farm flow implementation. No backend endpoint or API contract changes.

---

## Self-Review Notes

- Spec coverage: tasks cover app-scoped store, wizard steps, MapKit search, reverse geocoding, location permission string, local deletion, active-farm invariant, Lapor integration, keyboard-safe CTA, success actions, and verification.
- Red-flag scan: no deferred implementation markers are intentionally present.
- Type consistency: `AppEnvironment.farmStore`, `AddFarmView(selectedTab:)`, `FarmMapPickerView(coordinate:markerTitle:cameraPosition:onCoordinateSelected:onRegionChanged:)`, and `PlantScanViewModel.refreshActiveFarm()` are defined before use.
