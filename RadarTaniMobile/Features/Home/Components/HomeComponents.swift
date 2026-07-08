import SwiftUI

struct FarmSelectorPill: View {
    let farmName: String
    let crop: String

    var body: some View {
        Label("\(farmName) · \(crop)", systemImage: "leaf.fill")
            .font(.callout.weight(.semibold))
            .foregroundStyle(RTDColor.deepGreen)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RTDColor.softGreen, in: Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(RTDColor.textPrimary)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(RTDColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategoryChip: View {
    let title: String
    let systemImage: String?
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(isSelected ? RTDColor.textPrimary : color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? RTDColor.primaryGreen : color.opacity(0.12), in: Capsule())
    }
}
