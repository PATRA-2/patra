import SwiftUI

struct QuickActionCard: View {
    let title: String
    let systemImage: String

    var body: some View {
        RTDCard { Label(title, systemImage: systemImage).font(.headline) }
    }
}
