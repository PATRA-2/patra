import SwiftUI

struct RTDSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        SectionHeader(title: title, subtitle: subtitle)
    }
}
