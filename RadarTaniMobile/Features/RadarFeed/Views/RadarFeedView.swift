import SwiftUI

struct RadarFeedView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: RadarFeedViewModel?
    @State private var activeFarmName: String = "Lahan Anda"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RadarFeedSummaryCard(
                    farmName: activeFarmName,
                    radius: viewModel?.feedRadius ?? "10 km",
                    totalReports: viewModel?.reports.count ?? 0
                )

                RadiusInfoBanner(radius: viewModel?.feedRadius ?? "10 km", farmName: activeFarmName)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "Laporan Sekitar",
                        subtitle: "Kategori sesuai PRD: hama, bibit, dan kerja tani"
                    )

                    ReportCategoryFilter(
                        selectedCategory: selectedCategoryBinding,
                        reports: viewModel?.reports ?? [],
                        categories: viewModel?.availableCategories ?? []
                    )
                }

                LazyVStack(spacing: 16) {
                    ForEach(viewModel?.filteredReports ?? []) { report in
                        NavigationLink {
                            ReportDetailView(reportId: report.id)
                        } label: {
                            RadarReportCard(report: report)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if (viewModel?.filteredReports.isEmpty ?? true) {
                    EmptyRadarFeedState(categoryTitle: viewModel?.selectedCategoryTitle ?? "Semua Laporan")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .refreshable { await viewModel?.refresh() }
        .background(RTDColor.background.ignoresSafeArea())
        .navigationTitle("Radar Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Semua Laporan") { viewModel?.selectedCategory = nil }
                    ForEach(viewModel?.availableCategories ?? [], id: \.self) { category in
                        Button(category) { viewModel?.selectedCategory = category }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                }
                .foregroundStyle(RTDColor.textPrimary)
                .accessibilityLabel("Pilih kategori Radar Feed")
            }
        }
        .task {
            if viewModel == nil { viewModel = env.makeRadarFeedVM() }
            await viewModel?.load()
            await loadActiveFarmName()
        }
    }

    private var selectedCategoryBinding: Binding<String?> {
        Binding(
            get: { viewModel?.selectedCategory },
            set: { viewModel?.selectedCategory = $0 }
        )
    }

    private func loadActiveFarmName() async {
        if let page = try? await env.farms.farms(page: 1, pageSize: 100) {
            activeFarmName = page.items.first { $0.isActive }?.name ?? page.items.first?.name ?? "Lahan Anda"
        }
    }
}

private struct RadarFeedSummaryCard: View {
    let farmName: String
    let radius: String
    let totalReports: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RTDColor.primaryGreen)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.16), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text("Radar Feed")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Pantau laporan hama, kebutuhan bibit, dan kerja tani yang relevan dengan lahan Anda.")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                FeedMetricPill(title: "Lahan aktif", value: farmName, systemImage: "leaf.fill")
                FeedMetricPill(title: "Radius", value: radius, systemImage: "location.fill")
                FeedMetricPill(title: "Laporan", value: "\(totalReports)", systemImage: "doc.text.fill")
            }
            .padding(12)
            .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [RTDColor.deepGreen, Color(hex: "#315D34")], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 150))
                    .foregroundStyle(.white.opacity(0.1))
                    .offset(x: 24, y: 34)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: RTDColor.deepGreen.opacity(0.16), radius: 22, x: 0, y: 14)
    }
}

private struct FeedMetricPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RadiusInfoBanner: View {
    let radius: String
    let farmName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scope")
                .font(.title3)
                .foregroundStyle(RTDColor.deepGreen)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Jarak dihitung dari \(farmName)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(RTDColor.textPrimary)

                Text("Feed menampilkan laporan dalam radius \(radius). Backend menghitung radius dari lokasi lahan aktif Anda.")
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RTDColor.softGreen.opacity(0.72), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
    }
}

private struct RadarReportCard: View {
    let report: FeedReportOut

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    CategoryChip(title: report.category, systemImage: report.categoryIcon, color: report.categoryColor, isSelected: false)

                    Text(report.title)
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 8)

                RTDBadge(title: report.status, color: statusColor)
            }

            Text(report.summary)
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            RTDAsyncImage(url: report.imageUrl)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Divider()
                .overlay(RTDColor.borderSoft)

            HStack(spacing: 10) {
                Label(report.distance, systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textPrimary)

                Text("dari lahan Anda")
                    .font(.caption)
                    .foregroundStyle(RTDColor.textSecondary)

                Spacer(minLength: 8)

                Text(report.createdAt, format: .relative(presentation: .named))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch report.status {
        case "Terverifikasi": RTDColor.safeGreen
        case "Aktif": RTDColor.infoBlue
        default: RTDColor.warningOrange
        }
    }
}

private struct EmptyRadarFeedState: View {
    let categoryTitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(RTDColor.textSecondary)

            Text("Belum ada \(categoryTitle.lowercased())")
                .font(.headline)
                .foregroundStyle(RTDColor.textPrimary)

            Text("Laporan baru akan muncul setelah backend menerima data dari petani atau koperasi.")
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .rtdCard(radius: 18)
    }
}

#Preview {
    NavigationStack {
        RadarFeedView()
    }
    .environment(AppEnvironment())
}