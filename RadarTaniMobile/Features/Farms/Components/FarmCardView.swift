import SwiftUI

struct FarmCardView: View {
    let farm: Farm

    var body: some View {
        RTDCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(farm.name).font(.headline)
                Text("\(farm.crop) · \(farm.location)").font(.callout).foregroundStyle(RTDColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
