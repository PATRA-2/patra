import Foundation

struct RadarFeedService: Sendable {
    let client: APIClient

    func feed(lat: Double? = nil, long: Double? = nil, radiusKm: Double = 10,
              category: String? = nil, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedList<FeedReportOut> {
        try await client.request(PaginatedList<FeedReportOut>.self,
            endpoint: APIRoute.radarFeed(lat: lat, long: long, radiusKm: radiusKm, category: category, page: page, pageSize: pageSize))
    }

    func detail(_ id: UUID) async throws -> PlantReportOut {
        try await client.request(PlantReportOut.self, endpoint: APIRoute.feedDetail(id))
    }

    func mapReports(minLat: Double? = nil, maxLat: Double? = nil,
                    minLong: Double? = nil, maxLong: Double? = nil,
                    category: String? = nil) async throws -> MapItemsOut {
        try await client.request(MapItemsOut.self,
            endpoint: APIRoute.mapReports(minLat: minLat, maxLat: maxLat, minLong: minLong, maxLong: maxLong, category: category))
    }
}