import SwiftUI

struct ReportCategoryFilter: View {
    @Binding var selectedCategory: String?

    let reports: [FeedReportOut]
    let categories: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(
                    title: "Semua",
                    count: count(for: nil),
                    systemImage: "square.grid.2x2.fill",
                    color: RTDColor.deepGreen,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        title: category,
                        count: count(for: category),
                        systemImage: chipIcon(category),
                        color: chipColor(category),
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -20)
    }

    private func count(for category: String?) -> Int {
        guard let category else { return reports.count }
        return reports.filter { $0.category == category }.count
    }

    private func chipColor(_ category: String) -> Color {
        switch category {
        case "Hama": RTDColor.warningRed
        case "Penyakit": RTDColor.warningOrange
        case "Bibit": RTDColor.primaryGreen
        case "Kerja Tani": RTDColor.infoBlue
        default: RTDColor.infoBlue
        }
    }

    private func chipIcon(_ category: String) -> String {
        switch category {
        case "Hama": "exclamationmark.triangle.fill"
        case "Penyakit": "leaf.fill"
        case "Bibit": "leaf.fill"
        case "Kerja Tani": "person.2.fill"
        default: "mappin.circle.fill"
        }
    }
}

private struct FilterChip: View {
    let title: String
    let count: Int
    let systemImage: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))

                Text(title)
                    .lineLimit(1)

                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? RTDColor.deepGreen : color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(isSelected ? RTDColor.cardBackground.opacity(0.85) : color.opacity(0.12), in: Capsule())
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? RTDColor.textPrimary : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? RTDColor.primaryGreen : color.opacity(0.1), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? RTDColor.deepGreen.opacity(0.18) : color.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .fixedSize(horizontal: true, vertical: false)
    }
}