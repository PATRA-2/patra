import SwiftUI

struct RecommendationCard: View {
    let text: String
    var body: some View { RTDCard { Text(text).foregroundStyle(RTDColor.textSecondary) } }
}
