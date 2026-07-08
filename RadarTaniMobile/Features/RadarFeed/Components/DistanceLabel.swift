import SwiftUI

struct DistanceLabel: View {
    let distance: String
    var body: some View { Label("Berjarak \(distance) dari lahan Anda", systemImage: "location.fill") }
}
