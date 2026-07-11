import MapKit
import SwiftUI

struct RadarMapView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: RadarMapViewModel?
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedReportID: MapReportOut.ID?
    @State private var locationManager = LocationManager()

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedReportID) {
                ForEach(viewModel?.reports ?? []) { report in
                    Annotation(report.title, coordinate: CLLocationCoordinate2D(
                        latitude: report.coordinate.latitude, longitude: report.coordinate.longitude), anchor: .bottom) {
                        ReportMapAnnotation(report: report, isSelected: selectedReportID == report.id)
                    }
                    .tag(report.id)

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
                        Text("Sebaran laporan sekitar lahan Anda")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(18)
                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

                MapLegendView()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            if let report = viewModel?.report(with: selectedReportID) {
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
                if let initial = viewModel?.initialRegion {
                    position = .region(initial)
                }
            }
            if (viewModel?.reports.isEmpty ?? true) { await viewModel?.load() }
            if selectedReportID == nil { selectedReportID = viewModel?.reports.first?.id }
        }
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