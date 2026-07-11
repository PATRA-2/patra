import SwiftUI

struct ReportStepIndicator: View {
    let activeStep: Int

    private let steps = ["Foto", "Detail", "Analisis", "Kirim"]

    private var normalizedActiveStep: Int {
        min(max(activeStep, 1), steps.count)
    }

    private var progress: Double {
        guard steps.count > 1 else { return 1 }
        return Double(normalizedActiveStep - 1) / Double(steps.count - 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RTDSpacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                Text("Alur proses")
                    .font(.headline)
                    .foregroundStyle(RTDColor.textPrimary)

                Spacer(minLength: RTDSpacing.md)

                Text("Langkah \(normalizedActiveStep) dari \(steps.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTDColor.deepGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RTDColor.softGreen, in: Capsule())
                    .fixedSize(horizontal: true, vertical: false)
            }

            ZStack(alignment: .top) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(RTDColor.borderSoft)

                        Capsule()
                            .fill(RTDColor.primaryGreen)
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 35)
                .padding(.top, 14)
                .accessibilityHidden(true)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                        stepItem(number: index + 1, title: title)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RTDColor.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(RTDColor.borderSoft, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alur proses, langkah \(normalizedActiveStep) dari \(steps.count), \(steps[normalizedActiveStep - 1])")
    }

    private func stepItem(number: Int, title: String) -> some View {
        let isComplete = number < normalizedActiveStep
        let isActive = number == normalizedActiveStep

        return VStack(spacing: RTDSpacing.sm) {
            ZStack {
                Circle()
                    .fill(stepBackground(isComplete: isComplete, isActive: isActive))
                    .frame(width: 32, height: 32)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isActive ? RTDColor.textPrimary : RTDColor.textSecondary)
                        .monospacedDigit()
                }
            }

            Text(title)
                .font(.caption.weight(isActive ? .bold : .semibold))
                .foregroundStyle(number <= normalizedActiveStep ? RTDColor.deepGreen : RTDColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func stepBackground(isComplete: Bool, isActive: Bool) -> Color {
        if isComplete { return RTDColor.deepGreen }
        if isActive { return RTDColor.primaryGreen }
        return RTDColor.mutedBackground
    }
}
