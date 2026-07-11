import SwiftUI

struct MapLegendView: View {
    let selectedFarm: Farm?
    let selectedReportCategory: String?

    init(selectedFarm: Farm? = nil, selectedReportCategory: String? = nil) {
        self.selectedFarm = selectedFarm
        self.selectedReportCategory = selectedReportCategory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: selectedFarm == nil ? 0 : 10) {
            HStack(spacing: 8) {
                legendItem(
                    "Lahan",
                    color: RTDColor.deepGreen,
                    systemImage: "leaf.fill",
                    isSelected: selectedFarm != nil
                )
                legendItem("Hama", color: RTDColor.warningRed, isSelected: selectedReportCategory == "Hama")
                legendItem("Bibit", color: RTDColor.primaryGreen, isSelected: selectedReportCategory == "Bibit")
                legendItem("Kerja Tani", color: RTDColor.infoBlue, isSelected: selectedReportCategory == "Kerja Tani")
            }

            if let selectedFarm {
                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RTDColor.deepGreen)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lahan dipilih")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RTDColor.deepGreen)
                            .textCase(.uppercase)
                        Text(selectedFarm.name)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(RTDColor.textPrimary)
                            .lineLimit(1)
                        Text("\(selectedFarm.crop) · \(selectedFarm.location)")
                            .font(.caption)
                            .foregroundStyle(RTDColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lahan dipilih, \(selectedFarm.name), \(selectedFarm.crop), \(selectedFarm.location)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.2), value: selectedFarm?.id)
    }

    private func legendItem(
        _ title: String,
        color: Color,
        systemImage: String? = nil,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.caption.weight(isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? RTDColor.textPrimary : RTDColor.textSecondary)
        }
        .padding(.horizontal, isSelected ? 7 : 0)
        .padding(.vertical, 5)
        .background(color.opacity(isSelected ? 0.14 : 0), in: Capsule())
        .overlay {
            if isSelected {
                Capsule().stroke(color.opacity(0.35), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
