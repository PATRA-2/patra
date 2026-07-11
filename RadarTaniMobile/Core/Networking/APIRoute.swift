import Foundation

enum APIRoute {
    // Health
    static let health = APIEndpoint(path: "/health", method: .get, auth: .public_)

    // Auth
    static let login = APIEndpoint(path: "/auth/login", method: .post, auth: .public_)
    static let register = APIEndpoint(path: "/auth/register", method: .post, auth: .public_)
    static let refresh = APIEndpoint(path: "/auth/refresh", method: .post, auth: .public_)
    static let logout = APIEndpoint(path: "/auth/logout", method: .post, auth: .required)
    static let me = APIEndpoint(path: "/me", method: .get, auth: .required)

    // Farms
    static func farms(page: Int = 1, pageSize: Int = 20) -> APIEndpoint {
        .init(path: "/farms", method: .get,
              query: [.init(name: "page", value: "\(page)"),
                      .init(name: "page_size", value: "\(pageSize)")], auth: .required)
    }
    static let farmsCreate = APIEndpoint(path: "/farms", method: .post, auth: .required)
    static func farmUpdate(_ id: UUID) -> APIEndpoint { .init(path: "/farms/\(id)", method: .patch, auth: .required) }
    static func farmDelete(_ id: UUID, force: Bool = false) -> APIEndpoint {
    var e = APIEndpoint(path: "/farms/\(id)", method: .delete, auth: .required)
    if force { e.query = [.init(name: "force", value: "true")] }
    return e
}

    // Plant reports
    static let reportsCreate = APIEndpoint(path: "/plant-reports", method: .post, auth: .required, accepts: .multipart)
    static func reports(page: Int = 1, pageSize: Int = 20, category: String? = nil,
                        status: String? = nil, farmId: UUID? = nil) -> APIEndpoint {
        var query: [URLQueryItem] = [.init(name: "page", value: "\(page)"),
                                     .init(name: "page_size", value: "\(pageSize)")]
        if let category { query.append(.init(name: "category", value: category)) }
        if let status { query.append(.init(name: "status", value: status)) }
        if let farmId { query.append(.init(name: "farm_id", value: farmId.uuidString)) }
        return .init(path: "/plant-reports", method: .get, query: query, auth: .required)
    }
    static func report(_ id: UUID) -> APIEndpoint { .init(path: "/plant-reports/\(id)", method: .get, auth: .required) }
    static func reportUpdate(_ id: UUID) -> APIEndpoint { .init(path: "/plant-reports/\(id)", method: .patch, auth: .required) }
    static func reportDelete(_ id: UUID) -> APIEndpoint { .init(path: "/plant-reports/\(id)", method: .delete, auth: .required) }
    static let diagnose = APIEndpoint(path: "/plant-diagnoses", method: .post, auth: .required, accepts: .multipart)

    // Radar feed + map
    static func radarFeed(lat: Double? = nil, long: Double? = nil, radiusKm: Double = 10,
                          category: String? = nil, page: Int = 1, pageSize: Int = 20) -> APIEndpoint {
        var query: [URLQueryItem] = [.init(name: "radius_km", value: "\(radiusKm)"),
                                     .init(name: "page", value: "\(page)"),
                                     .init(name: "page_size", value: "\(pageSize)")]
        if let lat, let long {
            query.append(.init(name: "latitude", value: "\(lat)"))
            query.append(.init(name: "longitude", value: "\(long)"))
        }
        if let category { query.append(.init(name: "category", value: category)) }
        return .init(path: "/radar-feed/reports", method: .get, query: query, auth: .required)
    }
    static func feedDetail(_ id: UUID) -> APIEndpoint { .init(path: "/radar-feed/reports/\(id)", method: .get, auth: .required) }
    static func mapReports(minLat: Double? = nil, maxLat: Double? = nil,
                           minLong: Double? = nil, maxLong: Double? = nil,
                           category: String? = nil) -> APIEndpoint {
        var query: [URLQueryItem] = []
        if let minLat { query.append(.init(name: "min_latitude", value: "\(minLat)")) }
        if let maxLat { query.append(.init(name: "max_latitude", value: "\(maxLat)")) }
        if let minLong { query.append(.init(name: "min_longitude", value: "\(minLong)")) }
        if let maxLong { query.append(.init(name: "max_longitude", value: "\(maxLong)")) }
        if let category { query.append(.init(name: "category", value: category)) }
        return .init(path: "/map/reports", method: .get, query: query, auth: .required)
    }

    // Notifications
    static func notifications(page: Int = 1, pageSize: Int = 20, unreadOnly: Bool = false) -> APIEndpoint {
        APIEndpoint(path: "/notifications", method: .get,
            query: [.init(name: "page", value: "\(page)"),
                    .init(name: "page_size", value: "\(pageSize)"),
                    .init(name: "unread_only", value: "\(unreadOnly)")], auth: .required)
    }
    static func notificationRead(_ id: UUID) -> APIEndpoint { .init(path: "/notifications/\(id)/read", method: .patch, auth: .required) }
    static let notificationsReadAll = APIEndpoint(path: "/notifications/read-all", method: .patch, auth: .required)

    // Orders
    static func orders(page: Int = 1, pageSize: Int = 20) -> APIEndpoint {
        .init(path: "/pesticide-orders", method: .get,
              query: [.init(name: "page", value: "\(page)"),
                      .init(name: "page_size", value: "\(pageSize)")], auth: .required)
    }
    static let ordersCreate = APIEndpoint(path: "/pesticide-orders", method: .post, auth: .required)
}