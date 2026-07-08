import SwiftUI

struct RadarFeedView: View {
    @State private var viewModel = RadarFeedViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RadarFeedSegmentedControl()
                RadiusInfoBanner()

                LazyVStack(spacing: 10) {
                    ForEach(viewModel.reports) { report in
                        RadarReportCard(report: report)
                    }
                }
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Radar Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(RTDColor.textPrimary)
                .accessibilityLabel("Filter radar feed")
            }
        }
    }
}

private struct RadarFeedSegmentedControl: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Peta")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTDColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            Text("Daftar")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RTDColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RTDColor.primaryGreen, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(RTDColor.deepGreen.opacity(0.18), lineWidth: 1)
                }
                .accessibilityAddTraits(.isSelected)
        }
        .padding(2)
        .background(RTDColor.cardBackground, in: Capsule())
        .overlay {
            Capsule()
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct RadiusInfoBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(RTDColor.deepGreen)
                .padding(.top, 1)

            Text("Laporan di sekitar Anda berdasarkan radius 5 km dari lokasi lahan Anda.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(RTDColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RTDColor.softGreen.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }
}

private struct RadarReportCard: View {
    let report: RadarReport

    var body: some View {
        HStack(spacing: 12) {
            ReportThumbnail(distance: report.distance)
                .frame(width: 112, height: 94)

            VStack(alignment: .leading, spacing: 7) {
                Text(report.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RTDColor.textPrimary)
                    .lineLimit(1)

                Text(report.summary)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RTDColor.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                HStack(alignment: .bottom, spacing: 8) {
                    Text(report.timeAgo)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTDColor.textSecondary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Image(systemName: "mappin.and.ellipse")
                        .font(.title3)
                        .foregroundStyle(RTDColor.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 12)
            .padding(.trailing, 12)
        }
        .frame(minHeight: 94)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct ReportThumbnail: View {
    let distance: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RTDColor.mutedBackground

            PlaceholderCross()
                .padding(8)

            Text(distance)
                .font(.caption2.weight(.bold))
                .foregroundStyle(RTDColor.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RTDColor.cardBackground, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(RTDColor.borderSoft, lineWidth: 1)
                }
                .padding(6)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(RTDColor.borderSoft)
                .frame(width: 1)
        }
    }
}

private struct PlaceholderCross: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height))
                path.move(to: CGPoint(x: proxy.size.width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: proxy.size.height))
            }
            .stroke(RTDColor.textSecondary.opacity(0.35), lineWidth: 1.2)
        }
    }
}
