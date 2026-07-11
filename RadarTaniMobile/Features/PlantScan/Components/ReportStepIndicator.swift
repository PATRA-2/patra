import SwiftUI

struct ReportStepIndicator: View {
    let activeStep: Int

    private let steps = ["Foto", "Detail", "Analisis", "Kirim"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                let step = index + 1

                HStack(spacing: 6) {
                    Circle()
                        .fill(step <= activeStep ? RTDColor.primaryGreen : RTDColor.borderSoft)
                        .frame(width: 10, height: 10)

                    Text(title)
                        .font(.caption.weight(step == activeStep ? .bold : .semibold))
                        .foregroundStyle(step <= activeStep ? RTDColor.deepGreen : RTDColor.textSecondary)
                }

                if step < steps.count {
                    Rectangle()
                        .fill(step < activeStep ? RTDColor.primaryGreen : RTDColor.borderSoft)
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RTDColor.softGreen.opacity(0.7), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Langkah laporan \(activeStep) dari \(steps.count)")
    }
}
