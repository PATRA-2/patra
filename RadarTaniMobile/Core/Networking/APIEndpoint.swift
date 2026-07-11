import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum AuthRequirement: Sendable { case required, optional, public_ }
enum AcceptsType: Sendable { case json, multipart }

struct APIEndpoint: Sendable {
    var path: String
    var method: HTTPMethod = .get
    var query: [URLQueryItem] = []
    var jsonBody: Data? = nil
    var auth: AuthRequirement = .required
    var accepts: AcceptsType = .json

    func withBody(_ data: Data) -> APIEndpoint {
        var e = self; e.jsonBody = data; return e
    }
}