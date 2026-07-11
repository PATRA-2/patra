import SwiftUI

struct SymptomCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "viewfinder.circle.fill")
                .font(.title2)
                .foregroundStyle(RTDColor.warningOrange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Gejala yang terbaca")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text(text)
                    .font(.body)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .rtdCard()
    }
}
