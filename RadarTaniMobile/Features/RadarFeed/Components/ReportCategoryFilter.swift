import SwiftUI

struct ReportCategoryFilter: View {
    @Binding var selectedCategory: RadarReport.Category?

    let reports: [RadarReport]

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

                ForEach(RadarReport.Category.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        count: count(for: category),
                        systemImage: category.icon,
                        color: category.color,
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

    private func count(for category: RadarReport.Category?) -> Int {
        guard let category else { return reports.count }
        return reports.filter { $0.category == category }.count
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
