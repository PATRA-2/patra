import SwiftUI

struct ReportCategoryFilter: View {
    @Binding var selectedCategory: RadarReport.Category?
    var body: some View {
        HStack { CategoryChip(title: "Semua", systemImage: nil, color: RTDColor.deepGreen, isSelected: selectedCategory == nil) }
    }
}
