import SwiftUI
import MapKit

struct AddFarmView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddFarmViewModel?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.7956, longitude: 110.3695),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latitude: \(viewModel.coordinate.latitude, specifier: "%.6f")")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Longitude: \(viewModel.coordinate.longitude, specifier: "%.6f")")
                            .font(.caption).foregroundStyle(.secondary)
                        if !viewModel.detectedLocationName.isEmpty {
                            Text("📍 \(viewModel.detectedLocationName)")
                                .font(.caption2).foregroundStyle(RTDColor.infoBlue)
                        }
                    }

                    MapViewCoordinator(
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

                    HStack {
                        Button {
                            viewModel.detectCurrentLocation()
                        } label: {
                            Label("Deteksi Lokasi Saya", systemImage: "location.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(RTDColor.deepGreen)
                        Spacer()
                    }
                    .padding(.top, 4)
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

struct MapViewCoordinator: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.setRegion(region, animated: false)
        addPin(at: coordinate, on: map)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap(_:)))
        tap.numberOfTapsRequired = 1
        map.addGestureRecognizer(tap)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations)
        addPin(at: coordinate, on: map)
        if abs(map.region.center.latitude - region.center.latitude) > 0.0001 ||
            abs(map.region.center.longitude - region.center.longitude) > 0.0001 {
            map.setRegion(region, animated: true)
        }
    }

    private func addPin(at coord: CLLocationCoordinate2D, on map: MKMapView) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coord
        annotation.title = "📍 Lokasi Lahan"
        map.addAnnotation(annotation)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewCoordinator
        init(_ parent: MapViewCoordinator) { self.parent = parent }

        @objc func didTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .recognized else { return }
            let point = gesture.location(in: gesture.view)
            guard let map = gesture.view as? MKMapView else { return }
            let coord = map.convert(point, toCoordinateFrom: map)
            parent.coordinate = coord
            parent.region.center = coord
        }
    }
}