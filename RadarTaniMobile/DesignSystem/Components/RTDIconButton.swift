import SwiftUI

struct RTDIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 44, height: 44)
                .background(RTDColor.softGreen, in: Circle())
        }
        .foregroundStyle(RTDColor.deepGreen)
    }
}
