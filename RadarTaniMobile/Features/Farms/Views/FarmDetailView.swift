import SwiftUI
import MapKit

struct FarmDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @State var farm: FarmOut
    @State private var name: String
    @State private var crop: String
    @State private var location: String
    @State private var isActive: Bool
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var showForceDeleteConfirm = false
    @State private var isForceDelete = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(farm: FarmOut) {
        self._farm = State(initialValue: farm)
        self._name = State(initialValue: farm.name)
        self._crop = State(initialValue: farm.crop)
        self._location = State(initialValue: farm.location)
        self._isActive = State(initialValue: farm.isActive)
    }

    var body: some View {
        Form {
            Section("Data Lahan") {
                TextField("Nama", text: $name)
                TextField("Tanaman", text: $crop)
                TextField("Lokasi", text: $location)
                Toggle("Lahan aktif", isOn: $isActive)
            }

            Section("Koordinat") {
                Text("Lat: \(farm.coordinate.latitude, specifier: "%.6f")")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Lng: \(farm.coordinate.longitude, specifier: "%.6f")")
                    .font(.caption).foregroundStyle(.secondary)

                MapPreviewView(coordinate: CLLocationCoordinate2D(
                    latitude: farm.coordinate.latitude,
                    longitude: farm.coordinate.longitude))
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(RTDColor.warningRed).font(.callout) }
            }

            Section {
                Button("Simpan Perubahan") {
                    Task { await save() }
                }
                .disabled(isSaving || name.isEmpty || crop.isEmpty || location.isEmpty)
            }

            Section {
                Button("Hapus Lahan", role: .destructive) {
                    showDeleteConfirm = true
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Detail Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Hapus Lahan?", isPresented: $showDeleteConfirm) {
            Button("Hapus", role: .destructive) { Task { await delete() } }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Lahan '\(farm.name)' akan dihapus dari daftar Anda.")
        }
        .alert("Laporan Juga Ikut Terhapus", isPresented: $showForceDeleteConfirm) {
            Button("Hapus Semua", role: .destructive) { Task { isForceDelete = true; await delete() } }
            Button("Batal", role: .cancel) { isForceDelete = false }
        } message: {
            Text("Lahan '\(farm.name)' masih memiliki laporan. Semua laporan di lahan ini juga akan dihapus. Lanjutkan?")
        }
    }

    private func save() async {
        isSaving = true; defer { isSaving = false }
        do {
            let updated = try await env.farms.update(farm.id,
                FarmUpdate(name: name.isEmpty ? nil : name,
                          crop: crop.isEmpty ? nil : crop,
                          location: location.isEmpty ? nil : location,
                          coordinate: nil,
                          isActive: isActive))
            farm = updated
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal menyimpan."
        }
    }

    private func delete() async {
        isSaving = true; defer { isSaving = false }
        do {
            if isForceDelete {
                try await env.apiClient.requestVoid(APIRoute.farmDelete(farm.id, force: true))
            } else {
                try await env.farms.delete(farm.id)
            }
            dismiss()
        } catch let error as APIError {
            if case .server(let s) = error, s.code == "FARM_IN_USE" {
                showForceDeleteConfirm = true
                isSaving = false
            } else {
                errorMessage = error.userMessage
            }
        } catch {
            errorMessage = "Gagal menghapus."
        }
    }
}

struct MapPreviewView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isScrollEnabled = false
        map.isZoomEnabled = false
        map.isUserInteractionEnabled = false
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        map.addAnnotation(annotation)
        map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: false)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}
}