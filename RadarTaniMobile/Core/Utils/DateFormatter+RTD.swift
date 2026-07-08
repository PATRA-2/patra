import Foundation

extension DateFormatter {
    static let rtdShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
