import SwiftUI
import MapKit

struct AddFarmView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddFarmViewModel?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.7956, longitude: 110.3695),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State private var showMapPicker = false

    var body: some View {
        Form {
            Section("Data Lahan") {
                TextField("Nama lahan", text: textBinding(\.name))
                TextField("Tanaman", text: textBinding(\.crop))
                TextField("Lokasi desa", text: textBinding(\.location))
                Toggle("Lahan aktif", isOn: Binding(
                    get: { viewModel?.isActive ?? true },
                    set: { viewModel?.isActive = $0 }))
            }

            Section("Lokasi di Peta") {
                if let viewModel {
                    Text("Lat: \(viewModel.coordinate.latitude, specifier: "%.6f")")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Lng: \(viewModel.coordinate.longitude, specifier: "%.6f")")
                        .font(.caption).foregroundStyle(.secondary)

                    MapViewPicker(
                        coordinate: Binding(
                            get: { CLLocationCoordinate2D(
                                latitude: viewModel.coordinate.latitude,
                                longitude: viewModel.coordinate.longitude) },
                            set: { viewModel.coordinate = Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
                        ),
                        region: $region
                    )
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Deteksi Lokasi Saya") {
                        viewModel.requestLocationPermission()
                        viewModel.detectCurrentCoordinate()
                    }
                    .font(.caption).buttonStyle(.bordered)
                }
            }

            if let errorMessage = viewModel?.errorMessage {
                Section { Text(errorMessage).foregroundStyle(RTDColor.warningRed).font(.callout) }
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if viewModel?.isLoading == true { ProgressView() }
                        Text(viewModel?.isLoading == true ? "Menyimpan..." : "Simpan Lahan")
                    }
                }
                .disabled(viewModel?.isLoading == true)
            }
        }
        .navigationTitle("Tambah Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Batal") { dismiss() }
            }
        }
        .task { if viewModel == nil { viewModel = env.makeAddFarmVM() } }
    }

    private func textBinding(_ keyPath: WritableKeyPath<AddFarmViewModel, String>) -> Binding<String> {
        Binding(
            get: { viewModel?[keyPath: keyPath] ?? "" },
            set: { viewModel?[keyPath: keyPath] = $0 }
        )
    }

    private func submit() async {
        guard let viewModel else { return }
        if await viewModel.save() { dismiss() }
    }
}

struct MapViewPicker: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Lokasi Lahan"
        map.addAnnotation(annotation)

        let gesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(gesture)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if let annotation = map.annotations.first as? MKPointAnnotation {
            annotation.coordinate = coordinate
        }
        if map.region.center.latitude != region.center.latitude ||
            map.region.center.longitude != region.center.longitude {
            map.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewPicker

        init(_ parent: MapViewPicker) { self.parent = parent }

        @objc func handleTap(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            let point = gesture.location(in: gesture.view)
            guard let map = gesture.view as? MKMapView else { return }
            let coord = map.convert(point, toCoordinateFrom: map)
            parent.coordinate = coord
            parent.region.center = coord
            map.removeAnnotations(map.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = "Lokasi Lahan"
            map.addAnnotation(annotation)
        }
    }
}