import SwiftUI

struct DiagnosisScoreCard: View {
    let score: Int

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(RTDColor.borderSoft, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(score)%")
                    .font(.title3.bold())
                    .foregroundStyle(RTDColor.textPrimary)
            }
            .frame(width: 88, height: 88)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tingkat keyakinan AI \(score) persen")

            VStack(alignment: .leading, spacing: 6) {
                Text("Tingkat keyakinan AI")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)
                Text("Cukup kuat untuk pemantauan awal, tetapi tetap perlu verifikasi koperasi atau penyuluh.")
                    .font(.callout)
                    .foregroundStyle(RTDColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .rtdCard()
    }

    private var scoreColor: Color {
        score >= 75 ? RTDColor.safeGreen : RTDColor.warningOrange
    }
}
