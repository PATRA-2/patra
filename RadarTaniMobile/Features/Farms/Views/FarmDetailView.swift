import MapKit
import SwiftUI

struct FarmDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var farm: Farm
    @State private var isWorking = false
    @State private var showDeleteConfirm = false
    @State private var showForceDeleteConfirm = false
    @State private var errorMessage: String?

    init(farm: Farm) {
        self._farm = State(initialValue: farm)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                heroCard
                locationSection
                informationSection

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(RTDColor.warningRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RTDColor.warningRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("Kesalahan: \(errorMessage)")
                }

                managementSection
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(RTDColor.background)
        .navigationTitle("Detail Lahan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EditFarmView(farm: $farm)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(isWorking)
                .accessibilityHint("Membuka halaman untuk mengubah data lahan")
            }
        }
        .alert("Hapus Lahan?", isPresented: $showDeleteConfirm) {
            Button("Hapus", role: .destructive) { Task { await delete() } }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Lahan '\(farm.name)' akan dihapus dari daftar Anda.")
        }
        .alert("Lahan masih digunakan", isPresented: $showForceDeleteConfirm) {
            Button("Hapus Lahan dan Laporan", role: .destructive) {
                Task { await delete(force: true) }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Lahan ini masih terhubung ke laporan. Penghapusan paksa juga menghapus laporan terkait di server.")
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [RTDColor.deepGreen, RTDColor.leafGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "leaf.fill")
                .font(.system(size: 126, weight: .bold))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 28, y: -18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    Image(systemName: "camera.macro.circle.fill")
                        .font(.system(size: 52))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(RTDColor.primaryGreen, .white.opacity(0.18))
                        .accessibilityHidden(true)

                    Spacer()

                    Label(
                        farm.isActive ? "Lahan Aktif" : "Tidak Aktif",
                        systemImage: farm.isActive ? "checkmark.circle.fill" : "pause.circle.fill"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(farm.isActive ? RTDColor.deepGreen : .white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        farm.isActive ? RTDColor.primaryGreen : .white.opacity(0.16),
                        in: Capsule()
                    )
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(farm.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(farm.crop, systemImage: "leaf.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 188, alignment: .bottomLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: RTDColor.deepGreen.opacity(0.2), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(farm.name), tanaman \(farm.crop), \(farm.isActive ? "lahan aktif" : "tidak aktif")")
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Lokasi Lahan", systemImage: "mappin.and.ellipse")

            FarmLocationPreview(farm: farm)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                }

            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .foregroundStyle(RTDColor.deepGreen)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(farm.location)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RTDColor.textPrimary)
                    Text(coordinateText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(RTDColor.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .rtdCard(radius: 18)
        }
    }

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Informasi Lahan", systemImage: "info.circle.fill")

            VStack(spacing: 0) {
                FarmDetailInfoRow(
                    title: "Jenis tanaman",
                    value: farm.crop,
                    systemImage: "camera.macro"
                )
                Divider().padding(.leading, 58)
                FarmDetailInfoRow(
                    title: "Status",
                    value: farm.isActive ? "Aktif untuk laporan" : "Tidak aktif",
                    systemImage: farm.isActive ? "checkmark.seal.fill" : "pause.circle"
                )
                Divider().padding(.leading, 58)
                FarmDetailInfoRow(
                    title: "Terakhir diperbarui",
                    value: farm.updatedAt.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "clock.arrow.circlepath"
                )
            }
            .rtdCard(radius: 20)
        }
    }

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Kelola Lahan", systemImage: "slider.horizontal.3")

            NavigationLink {
                EditFarmView(farm: $farm)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(RTDColor.deepGreen)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Edit Data Lahan")
                            .font(.headline)
                            .foregroundStyle(RTDColor.textPrimary)
                        Text("Ubah nama, tanaman, lokasi, atau status")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTDColor.textSecondary)
                        .accessibilityHidden(true)
                }
                .padding(16)
                .background(RTDColor.softGreen, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isWorking)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Label("Hapus Lahan", systemImage: "trash")
                    if isWorking { ProgressView().controlSize(.small) }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.headline)
                .foregroundStyle(RTDColor.warningRed)
                .padding(16)
                .background(RTDColor.warningRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
        }
    }

    private var coordinateText: String {
        String(format: "%.6f, %.6f", farm.coordinate.latitude, farm.coordinate.longitude)
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(RTDColor.textPrimary)
    }

    private func delete(force: Bool = false) async {
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await env.farmStore.deleteFarm(id: farm.id, force: force)
            dismiss()
        } catch let APIError.server(serverError) where serverError.code == "FARM_IN_USE" && !force {
            showForceDeleteConfirm = true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Lahan gagal dihapus dari server."
        }
    }
}

private struct FarmDetailInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(RTDColor.deepGreen)
                .frame(width: 38, height: 38)
                .background(RTDColor.softGreen, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RTDColor.textPrimary)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .accessibilityElement(children: .combine)
    }
}

private struct FarmLocationPreview: View {
    let farm: Farm
    @State private var position: MapCameraPosition

    init(farm: Farm) {
        self.farm = farm
        self._position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: farm.coordinate.latitude,
                longitude: farm.coordinate.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )))
    }

    var body: some View {
        Map(position: $position, interactionModes: []) {
            Marker(
                farm.name,
                systemImage: "leaf.fill",
                coordinate: CLLocationCoordinate2D(
                    latitude: farm.coordinate.latitude,
                    longitude: farm.coordinate.longitude
                )
            )
            .tint(RTDColor.deepGreen)
        }
        .mapStyle(.hybrid(elevation: .flat))
        .accessibilityLabel("Peta lokasi \(farm.name)")
        .accessibilityHint("Menampilkan titik lokasi lahan secara statis")
    }
}
