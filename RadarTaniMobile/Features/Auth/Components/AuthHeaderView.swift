import SwiftUI

struct AuthHeaderView: View {
    var title = "Radar Tani Desa"
    var subtitle = "Peringatan dini hama untuk petani dan koperasi desa."

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(RTDFont.largeTitle).foregroundStyle(RTDColor.textPrimary)
            Text(subtitle).font(RTDFont.body).foregroundStyle(RTDColor.textSecondary)
        }
    }
}
