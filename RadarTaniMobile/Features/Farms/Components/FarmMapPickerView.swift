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
