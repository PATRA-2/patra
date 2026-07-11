import MapKit
import SwiftUI

struct FarmMapPickerView: View {
    @Binding var coordinate: Coordinate?
    @Bindable var locationManager: LocationManager
    let markerTitle: String
    let onCoordinateSelected: (Coordinate) -> Void
    let onRegionChanged: (MKCoordinateRegion) -> Void

    @Environment(\.openURL) private var openURL
    @State private var position: MapCameraPosition

    init(
        coordinate: Binding<Coordinate?>,
        locationManager: LocationManager,
        markerTitle: String = "Lokasi lahan",
        onCoordinateSelected: @escaping (Coordinate) -> Void = { _ in },
        onRegionChanged: @escaping (MKCoordinateRegion) -> Void = { _ in }
    ) {
        self._coordinate = coordinate
        self.locationManager = locationManager
        self.markerTitle = markerTitle
        self.onCoordinateSelected = onCoordinateSelected
        self.onRegionChanged = onRegionChanged

        let initialCoordinate = coordinate.wrappedValue ?? Self.defaultCoordinate
        self._position = State(initialValue: .region(Self.region(around: initialCoordinate)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            map

            Button {
                HapticManager.selection()
                locationManager.requestCurrentLocation()
            } label: {
                HStack(spacing: 10) {
                    if locationManager.isLocating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(locationManager.isLocating ? "Mencari lokasi..." : "Gunakan Lokasi Saya")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(RTDColor.deepGreen, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(locationManager.isLocating)
            .accessibilityHint("Memilih koordinat perangkat sebagai lokasi lahan")

            if let errorMessage = locationManager.errorMessage {
                locationError(message: errorMessage)
            }

            if let coordinate {
                coordinateSummary(coordinate)
            } else {
                Label("Ketuk peta atau gunakan GPS untuk menempatkan pin lahan.", systemImage: "hand.tap.fill")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var map: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()

                if let coordinate {
                    Marker(
                        markerTitle,
                        systemImage: "leaf.fill",
                        coordinate: coordinate.clLocationCoordinate
                    )
                    .tint(RTDColor.deepGreen)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onTapGesture { screenPoint in
                guard let mapCoordinate = proxy.convert(screenPoint, from: .local) else { return }
                select(
                    Coordinate(
                        latitude: mapCoordinate.latitude,
                        longitude: mapCoordinate.longitude
                    ),
                    moveCamera: false,
                    shouldResolveName: true
                )
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                onRegionChanged(context.region)
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            Label("Ketuk untuk memindahkan pin", systemImage: "mappin.and.ellipse")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTDColor.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(12)
        }
        .accessibilityLabel("Peta pemilihan lokasi lahan")
        .onChange(of: locationManager.coordinate) { _, newCoordinate in
            guard let newCoordinate else { return }
            select(newCoordinate, moveCamera: true, shouldResolveName: true)
        }
        .onChange(of: coordinate) { oldCoordinate, newCoordinate in
            guard let newCoordinate, newCoordinate != oldCoordinate else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                position = .region(Self.region(around: newCoordinate))
            }
        }
    }

    private func locationError(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(message, systemImage: "location.slash.fill")
                .font(.callout)
                .foregroundStyle(RTDColor.warningRed)
                .fixedSize(horizontal: false, vertical: true)

            if locationManager.isAuthorizationDenied {
                Button("Buka Pengaturan") {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(settingsURL)
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(RTDColor.deepGreen)
            }
        }
        .padding(14)
        .background(RTDColor.warningRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func coordinateSummary(_ coordinate: Coordinate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(RTDColor.safeGreen)

            VStack(alignment: .leading, spacing: 3) {
                Text("Koordinat dipilih")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                Text(CoordinateFormatter.format(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ))
                .font(.callout.monospacedDigit())
                .foregroundStyle(RTDColor.textPrimary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func select(
        _ coordinate: Coordinate,
        moveCamera: Bool,
        shouldResolveName: Bool
    ) {
        self.coordinate = coordinate
        HapticManager.selection()
        if shouldResolveName {
            onCoordinateSelected(coordinate)
        }

        guard moveCamera else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            position = .region(Self.region(around: coordinate))
        }
    }

    private static let defaultCoordinate = Coordinate(latitude: -7.79560, longitude: 110.36950)

    private static func region(around coordinate: Coordinate) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate.clLocationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    }
}

struct FarmLocationPreview: View {
    let coordinate: Coordinate
    let title: String

    @State private var position: MapCameraPosition

    init(coordinate: Coordinate, title: String) {
        self.coordinate = coordinate
        self.title = title
        self._position = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: coordinate.clLocationCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            )
        )
    }

    var body: some View {
        Map(position: $position, interactionModes: []) {
            Marker(title, systemImage: "leaf.fill", coordinate: coordinate.clLocationCoordinate)
                .tint(RTDColor.deepGreen)
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel("Pratinjau lokasi lahan (title)")
    }
}

private extension Coordinate {
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
