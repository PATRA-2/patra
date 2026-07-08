import SwiftUI

struct ReportCardView: View {
    let report: RadarReport
    var body: some View { RTDCard { Text(report.title).font(.headline) } }
}
