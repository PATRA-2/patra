import Foundation

extension Double {
    var rtdKilometerText: String {
        "\(formatted(.number.precision(.fractionLength(0...1)))) KM"
    }
}
