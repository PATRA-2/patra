import SwiftUI

struct ShareToVillageButton: View {
    let action: () -> Void
    var body: some View { RTDButton(title: "Bagikan Solusi ke Desa", systemImage: "paperplane.fill", action: action) }
}
