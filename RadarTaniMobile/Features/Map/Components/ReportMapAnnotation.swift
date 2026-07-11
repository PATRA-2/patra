import SwiftUI

struct ReportMapAnnotation: View {
    let report: MapReportOut
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: report.categoryIcon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(report.category == "Bibit" ? RTDColor.textPrimary : .white)
                .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                .background(report.categoryColor, in: Circle())
                .overlay {
                    Circle().stroke(.white, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)

            Image(systemName: "triangle.fill")
                .font(.system(size: 9))
                .foregroundStyle(report.categoryColor)
                .rotationEffect(.degrees(180))
                .offset(y: -7)
        }
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.snappy(duration: 0.18), value: isSelected)
    }
}