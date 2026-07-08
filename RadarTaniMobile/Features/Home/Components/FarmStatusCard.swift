import SwiftUI

struct FarmStatusCard: View {
    let farm: Farm

    var body: some View {
        RTDCard { Text("\(farm.name) · \(farm.crop)").font(.headline) }
    }
}
