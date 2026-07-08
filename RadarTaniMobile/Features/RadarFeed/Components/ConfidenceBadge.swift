import SwiftUI

struct ConfidenceBadge: View {
    let score: Int
    var body: some View { RTDBadge(title: "Confidence \(score)%", color: score >= 80 ? RTDColor.safeGreen : RTDColor.warningOrange) }
}
