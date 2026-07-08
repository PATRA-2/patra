import SwiftUI

struct RTDTextField: View {
    let title: String
    let prompt: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(RTDColor.textSecondary)
            TextField(prompt, text: $text)
                .padding(14)
                .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
