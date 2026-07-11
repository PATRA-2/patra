# In-Memory Add Farm Flow Design

Date: 2026-07-11

## Goal

Build the `Tambah Lahan` user flow as a native SwiftUI, front-end-only experience. New farms are stored in memory, become the single active farm, appear immediately in the `Lahan` list, and become the active context for `Lapor`. Add local farm deletion with confirmation.

## Scope

- Replace backend-driven farm list/add/delete behavior in the relevant UI with an app-scoped in-memory `FarmStore`.
- Keep `HomeView.swift`, backend endpoints, and API contracts unchanged.
- Use Radar Tani design system components/colors, SwiftUI, MapKit, Core Location, Dynamic Type-friendly text, VoiceOver labels, keyboard-safe CTA placement, and haptic feedback.
- Persist state only for the current app session.

## Architecture

`AppEnvironment` owns one `FarmStore` initialized from `MockFarm.samples`. The store exposes `farms`, `activeFarm`, `addFarm`, `setActiveFarm`, and `deleteFarm`. It normalizes state so at most one farm is active.

`Farm` keeps a stable `UUID`, mutable `isActive`, and a coordinate. The initializer remains source-compatible with current fixtures and service models.

`FarmListView` reads `FarmStore` from the environment. It opens `AddFarmView` through navigation push, renders the list from memory, and deletes locally after confirmation. If the active farm is deleted, `FarmStore` makes the first remaining farm active. If the last farm is deleted, `activeFarm` becomes `nil`.

`PlantScanView` and its view model use `FarmStore.activeFarm` instead of fetching active farm data from `FarmService`. Existing plant analysis tasks keep their farm snapshot when enqueued.

## Add Farm Wizard

`AddFarmViewModel` owns all draft and UI state for a three-step wizard: current step, crop selection, custom crop, name, location text, selected coordinate, selected place details, suggestions, loading states, validation messages, save loading, and success state.

Step 1, `Informasi Lahan`, validates the farm name and crop. Crop choices are `Padi`, `Cabai`, `Jagung`, `Tomat`, `Bawang`, and `Lainnya`. Choosing `Lainnya` reveals a manual crop input. The step informs users that the new farm will become active.

Step 2, `Tentukan Lokasi`, uses a search field labeled `Cari nama tempat, desa, atau daerah`. Search suggestions are powered by `MKLocalSearchCompleter` with a 300 ms debounce and prioritized around the current map region. Choosing a suggestion fills the location name/address, moves the map camera, and places the pin. Tapping the map or using `Gunakan Lokasi Saya` updates the pin and triggers reverse geocoding. While reverse geocoding is in progress, the UI shows `Mencari nama lokasi...` and disables `Lanjut`. Failures keep the coordinate, show `Nama lokasi belum ditemukan`, and allow manual location input. `Lanjut` is enabled only when a coordinate exists and the final location name has at least three characters.

Step 3, `Konfirmasi Lahan`, shows the entered farm name, crop, selected location, coordinates formatted to five decimal places, and a compact map preview. It warns that the previous active farm will be deactivated. `Simpan Lahan` shows a short loading state, calls `FarmStore.addFarm`, and triggers success haptic. The success state offers `Lihat Lahan` and `Mulai Lapor`; `Mulai Lapor` switches the selected tab to `Lapor`.

## Location Services

`LocationManager` supports a one-shot location request with loading, authorization, coordinate, and friendly error state. Denied/restricted authorization or GPS failure does not block manual map pin selection.

`FarmPlaceSearchService` wraps `MKLocalSearchCompleter` and completion selection. `FarmPlaceResolving` abstracts reverse geocoding so MapKit behavior can be replaced in tests. `FarmPlaceResult` contains `displayName`, `formattedAddress`, and `Coordinate`.

Slow search or reverse-geocode results must not overwrite newer user selections. The view model cancels stale lookup tasks or ignores results whose coordinate/request token is no longer current.

## Navigation And Recovery

Primary CTAs use `safeAreaInset` so they remain visible above the keyboard and home indicator. Back navigation moves to the previous wizard step. Attempting to leave step 1 with a non-empty draft shows a discard confirmation. Draft fields, chosen suggestions, manual fallback input, and coordinates persist when navigating back and forward.

## Deletion

Farm deletion is local-only. The list provides a delete affordance with a confirmation alert. Confirming deletion removes the farm from `FarmStore`. If the deleted farm was active, the first remaining farm becomes active. Deleting does not call backend APIs and does not delete report history.

## Testing

- Verify `Tambah Lahan` opens step 1 through navigation push and cannot continue with invalid fields.
- Verify all crop choices, including custom `Lainnya` validation.
- Verify search suggestions, suggestion selection, map pin/camera movement, map tap reverse geocoding, GPS, denied/restricted location, GPS failure, search failure, empty reverse-geocode result, and manual fallback.
- Verify location summary and confirmation coordinates match the marker using five decimal places.
- Verify saving inserts the farm, deactivates the previous active farm, and preserves the invariant that only one farm is active.
- Verify `Lihat Lahan` returns to the list and `Mulai Lapor` opens `Lapor` with the new active farm.
- Verify local delete confirmation, active-farm fallback, deleting non-active farms, and deleting the last farm.
- Verify back navigation, discard confirmation, keyboard safety, light/dark appearance where supported, large Dynamic Type, VoiceOver labels, and safe area behavior.
- Run `git diff --check` and an iPhone 17 Pro iOS 26.5 simulator `xcodebuild` build.

## Decisions

- Use the in-memory `FarmStore` approach only.
- New farms always become active.
- Deletion is local-only with confirmation.
- Location is one point coordinate, not a polygon or acreage.
- Search and geocoding may require network access; manual fallback remains available.
