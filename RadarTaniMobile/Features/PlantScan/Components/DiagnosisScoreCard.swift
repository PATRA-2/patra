import SwiftUI

struct DiagnosisScoreCard: View {
    let score: Int
    var body: some View { RTDCard { Text("Confidence \(score)%").font(.headline) } }
}
