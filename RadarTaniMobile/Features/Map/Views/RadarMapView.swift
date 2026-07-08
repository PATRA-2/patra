import MapKit
import SwiftUI

struct RadarMapView: View {
    @State private var viewModel = RadarMapViewModel()
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedReportID: RadarMapReport.ID?

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedReportID) {
                ForEach(viewModel.reports) { report in
                    Annotation(report.title, coordinate: report.coordinate, anchor: .bottom) {
                        ReportMapAnnotation(report: report, isSelected: selectedReportID == report.id)
                    }
                    .tag(report.id)

                    if report.category == .pest {
                        MapCircle(center: report.coordinate, radius: 1_500)
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
            if let report = viewModel.report(with: selectedReportID) {
                SelectedMapReportCard(report: report)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .background(RTDColor.background)
        .navigationTitle("Peta")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            position = .region(viewModel.initialRegion)
            selectedReportID = viewModel.reports.first?.id
        }
    }
}

private struct SelectedMapReportCard: View {
    let report: RadarMapReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryChip(title: report.category.rawValue, systemImage: report.category.icon, color: report.category.color, isSelected: false)
                Spacer()
                DistanceLabel(distance: report.distance)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
            }

            Text(report.title)
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)
            Text(report.summary)
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
            Text(report.status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(report.status == "Terverifikasi" ? RTDColor.safeGreen : RTDColor.warningOrange)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
    }
}
