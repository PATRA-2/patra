import SwiftUI

struct RecommendationCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checklist.checked")
                .font(.title2)
                .foregroundStyle(RTDColor.safeGreen)

            VStack(alignment: .leading, spacing: 6) {
                Text("Saran pemantauan awal")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text(text)
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(RTDColor.softGreen.opacity(0.66), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(RTDColor.leafGreen.opacity(0.28), lineWidth: 1)
        }
    }
}
