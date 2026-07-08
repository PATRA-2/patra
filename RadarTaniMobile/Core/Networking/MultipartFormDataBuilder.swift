import Foundation

struct MultipartFormDataBuilder {
    let boundary = UUID().uuidString
    private(set) var data = Data()

    mutating func appendField(name: String, value: String) {
        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        data.appendString("\(value)\r\n")
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
