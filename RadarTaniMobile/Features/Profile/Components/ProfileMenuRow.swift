import SwiftUI

struct ProfileMenuRow: View {
    let title: String
    let systemImage: String
    var body: some View { Label(title, systemImage: systemImage).font(.headline) }
}
