import SwiftUI

struct RTDTextField: View {
    let title: String
    let prompt: String
    @Binding var text: String

    init(title: String, prompt: String = "", text: Binding<String>) {
        self.title = title
        self.prompt = prompt
        self._text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(RTDColor.textSecondary)
            TextField(prompt, text: $text)
                .padding(14)
                .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
