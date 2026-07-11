import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

nonisolated enum AuthRequirement: Sendable { case required, optional, public_ }
nonisolated enum AcceptsType: Sendable { case json, multipart }

nonisolated struct APIEndpoint: Sendable {
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
