import MapKit
import SwiftUI

enum FarmMapPickerMode {
    case interactive
    case preview
}

struct FarmMapPickerView: View {
    let coordinate: Coordinate?
    let markerTitle: String
    let isResolving: Bool
    let mode: FarmMapPickerMode
    @Binding var cameraPosition: MapCameraPosition
    let onCoordinateSelected: (Coordinate) -> Void
    let onRegionChanged: (MKCoordinateRegion) -> Void

    @State private var isCalloutVisible = true

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let coordinate {
                    Annotation(
                        markerTitle,
                        coordinate: CLLocationCoordinate2D(
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        ),
                        anchor: .bottom
                    ) {
                        markerAnnotation
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onTapGesture { point in
                guard mode == .interactive,
                      let coordinate = proxy.convert(point, from: .local) else { return }
                isCalloutVisible = true
                onCoordinateSelected(Coordinate(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ))
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                guard mode == .interactive else { return }
                onRegionChanged(context.region)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .onChange(of: coordinate) { _, newCoordinate in
            guard newCoordinate != nil else { return }
            isCalloutVisible = true
        }
        .onChange(of: isResolving) { _, resolving in
            if resolving { isCalloutVisible = true }
        }
        .accessibilityLabel(mode == .interactive ? "Peta pemilihan lokasi lahan" : "Pratinjau lokasi lahan")
        .accessibilityHint(
            mode == .interactive
                ? "Ketuk peta untuk memindahkan pin. Ketuk pin untuk menampilkan nama lokasi."
                : "Peta hanya menampilkan lokasi lahan yang sudah dipilih."
        )
    }

    private var markerAnnotation: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCalloutVisible.toggle()
            }
        } label: {
            VStack(spacing: 5) {
                if isCalloutVisible {
                    HStack(spacing: 7) {
                        if isResolving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(RTDColor.deepGreen)
                        }

                        Text(markerTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: 220, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(RTDColor.borderSoft, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
                }

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(RTDColor.deepGreen, .white)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .frame(width: 48, height: 48)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isResolving ? "Mencari nama lokasi" : markerTitle)
        .accessibilityHint("Ketuk untuk menampilkan atau menyembunyikan nama lokasi")
    }
}
