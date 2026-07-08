import SwiftUI

struct SymptomCard: View {
    let text: String
    var body: some View { RTDCard { Text(text).foregroundStyle(RTDColor.textSecondary) } }
}
