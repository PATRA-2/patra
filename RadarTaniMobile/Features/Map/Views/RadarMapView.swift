import MapKit
import SwiftUI

private enum RadarMapSelection: Hashable {
    case farm(Farm.ID)
    case report(MapReportOut.ID)
}

struct RadarMapView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: RadarMapViewModel?
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedMapItem: RadarMapSelection?
    @State private var locationManager = LocationManager()
    @State private var hasPositionedInitialRegion = false

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedMapItem) {
                if let farm = viewModel?.activeFarm {
                    Annotation(
                        "Lahan aktif: \(farm.name)",
                        coordinate: CLLocationCoordinate2D(
                            latitude: farm.coordinate.latitude,
                            longitude: farm.coordinate.longitude
                        ),
                        anchor: .bottom
                    ) {
                        ActiveFarmMapAnnotation(
                            farm: farm,
                            isSelected: selectedFarm?.id == farm.id
                        )
                    }
                    .tag(RadarMapSelection.farm(farm.id))
                }

                ForEach(viewModel?.reports ?? []) { report in
                    Annotation(report.title, coordinate: CLLocationCoordinate2D(
                        latitude: report.coordinate.latitude, longitude: report.coordinate.longitude), anchor: .bottom) {
                        ReportMapAnnotation(report: report, isSelected: selectedReport?.id == report.id)
                    }
                    .tag(RadarMapSelection.report(report.id))

                    if report.category == "Hama" {
                        MapCircle(center: CLLocationCoordinate2D(
                            latitude: report.coordinate.latitude, longitude: report.coordinate.longitude), radius: 1_500)
                            .foregroundStyle(RTDColor.warningRed.opacity(0.12))
                            .stroke(RTDColor.warningRed.opacity(0.45), lineWidth: 1)
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Peta Radar")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(RTDColor.textPrimary)
                        Text("Titik lahan aktif dan sebaran laporan")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(18)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

                MapLegendView(
                    selectedFarm: selectedFarm,
                    selectedReportCategory: selectedReport?.category
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            if let farm = selectedFarm {
                SelectedMapFarmCard(farm: farm)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            } else if let report = selectedReport {
                SelectedMapReportCard(report: report)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                locationManager.checkAuthorization()
                locationManager.requestOneShot { coord in
                    withAnimation {
                        position = .region(MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
                    }
                }
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(RTDColor.deepGreen)
                    .background(Circle().fill(.regularMaterial).frame(width: 48, height: 48))
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .background(RTDColor.background)
        .navigationTitle("Peta")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = env.makeRadarMapVM()
            }

            await viewModel?.loadActiveFarm()

            if !hasPositionedInitialRegion, let initial = viewModel?.preferredInitialRegion {
                position = .region(initial)
                hasPositionedInitialRegion = true
            }

            if (viewModel?.reports.isEmpty ?? true) {
                await viewModel?.load(region: viewModel?.preferredInitialRegion)
            }
            if selectedMapItem == nil {
                if let firstReport = viewModel?.reports.first {
                    selectedMapItem = .report(firstReport.id)
                } else if let activeFarm = viewModel?.activeFarm {
                    selectedMapItem = .farm(activeFarm.id)
                }
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            Task { await viewModel?.load(region: context.region) }
        }
    }

    private var selectedFarm: Farm? {
        guard case let .farm(id) = selectedMapItem,
              let farm = viewModel?.activeFarm,
              farm.id == id else { return nil }
        return farm
    }

    private var selectedReport: MapReportOut? {
        guard case let .report(id) = selectedMapItem else { return nil }
        return viewModel?.report(with: id)
    }
}

private struct ActiveFarmMapAnnotation: View {
    let farm: Farm
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lahan Aktif")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTDColor.deepGreen)
                Text(farm.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RTDColor.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: 170, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(RTDColor.deepGreen.opacity(isSelected ? 0.75 : 0.35), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 7, y: 3)

            ZStack {
                Circle()
                    .fill(isSelected ? RTDColor.primaryGreen : .white)
                Circle()
                    .stroke(RTDColor.deepGreen, lineWidth: isSelected ? 4 : 3)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(RTDColor.deepGreen)
            }
            .frame(width: 42, height: 42)
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.snappy(duration: 0.2), value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lahan aktif, \(farm.name), \(farm.location)")
        .accessibilityHint(isSelected ? "Lahan sedang dipilih" : "Ketuk untuk melihat informasi lahan")
    }
}

private struct SelectedMapFarmCard: View {
    let farm: Farm

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("Lahan Aktif", systemImage: "leaf.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RTDColor.deepGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RTDColor.softGreen, in: Capsule())

                Spacer()

                Text(farm.crop)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
            }

            Text(farm.name)
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)

            Label(farm.location, systemImage: "mappin.and.ellipse")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)

            Text(String(
                format: "%.6f, %.6f",
                farm.coordinate.latitude,
                farm.coordinate.longitude
            ))
            .font(.caption.monospacedDigit())
            .foregroundStyle(RTDColor.textSecondary)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lahan aktif, \(farm.name), tanaman \(farm.crop), lokasi \(farm.location)")
    }
}

private struct SelectedMapReportCard: View {
    let report: MapReportOut

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryChip(title: report.category, systemImage: report.categoryIcon, color: report.categoryColor, isSelected: false)
                Spacer()
                DistanceLabel(distance: report.category)
            }

            Text(report.title)
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)
            Text(report.status)
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
            Text(report.createdAt, format: .relative(presentation: .named))
                .font(.caption.weight(.semibold))
                .foregroundStyle(report.status == "Terverifikasi" ? RTDColor.safeGreen : RTDColor.warningOrange)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
    }
}
