import SwiftUI

struct RTDErrorView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout.weight(.semibold))
            .foregroundStyle(RTDColor.warningRed)
            .padding(16)
            .background(RTDColor.warningRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
