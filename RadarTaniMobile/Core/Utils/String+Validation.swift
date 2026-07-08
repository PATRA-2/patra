import Foundation

extension String {
    var rtdIsValidEmail: Bool {
        contains("@") && contains(".")
    }
}
