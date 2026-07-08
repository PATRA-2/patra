import Foundation

enum CoordinateFormatter {
    static func format(latitude: Double, longitude: Double) -> String {
        "\(latitude.formatted(.number.precision(.fractionLength(5)))), \(longitude.formatted(.number.precision(.fractionLength(5))))"
    }
}
