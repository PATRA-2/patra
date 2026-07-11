import Foundation

struct MultipartFormDataBuilder {
    let boundary: String
    private(set) var body = Data()

    init() { boundary = "----RTDBoundary" + UUID().uuidString }

    mutating func append(_ name: String, _ value: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    mutating func appendFile(_ name: String, data: Data, filename: String, mimeType: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    var httpBody: Data {
        var b = body
        b.appendString("--\(boundary)--\r\n")
        return b
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }
}

private extension Data {
    mutating func appendString(_ string: String) { append(Data(string.utf8)) }
}