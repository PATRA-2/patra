import SwiftUI

struct RadarSummaryHeroCard<Content: View>: View {
    let decorativeSystemImage: String
    let content: Content

    init(
        decorativeSystemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.decorativeSystemImage = decorativeSystemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [RTDColor.deepGreen, Color(hex: "#315D34")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: decorativeSystemImage)
                    .font(.system(size: 150))
                    .foregroundStyle(.white.opacity(0.1))
                    .offset(x: 24, y: 34)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: RTDColor.deepGreen.opacity(0.16), radius: 22, x: 0, y: 14)
    }
}

struct RadarSummaryMetric: View {
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
        .accessibilityElement(children: .combine)
    }
}
