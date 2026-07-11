import Foundation
import UIKit

struct ReportService: Sendable {
    let client: APIClient

    func create(image: UIImage, title: String, category: String, description: String?,
                farmId: UUID?, latitude: Double?, longitude: Double?,
                publishToFeed: Bool) async throws -> PlantReportOut {
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw APIError.unknown
        }
        var builder = MultipartFormDataBuilder()
        builder.appendFile("image", data: jpegData, filename: "report.jpg", mimeType: "image/jpeg")
        builder.append("title", title)
        builder.append("category", category)
        if let description { builder.append("description", description) }
        if let farmId { builder.append("farm_id", farmId.uuidString) }
        if let latitude, let longitude {
            builder.append("latitude", "\(latitude)")
            builder.append("longitude", "\(longitude)")
        }
        builder.append("publish_to_feed", publishToFeed ? "true" : "false")
        return try await client.upload(PlantReportOut.self,
            endpoint: APIRoute.reportsCreate,
            body: builder.httpBody, contentType: builder.contentType)
    }

    func list(page: Int = 1, pageSize: Int = 20, category: String? = nil,
              status: String? = nil, farmId: UUID? = nil) async throws -> PaginatedList<PlantReportOut> {
        try await client.request(PaginatedList<PlantReportOut>.self,
            endpoint: APIRoute.reports(page: page, pageSize: pageSize, category: category, status: status, farmId: farmId))
    }

    func detail(_ id: UUID) async throws -> PlantReportOut {
        try await client.request(PlantReportOut.self, endpoint: APIRoute.report(id))
    }

    func update(_ id: UUID, changes: PlantReportUpdate) async throws -> PlantReportOut {
        let body = try APICoder.encoder.encode(changes)
        return try await client.request(
            PlantReportOut.self,
            endpoint: APIRoute.reportUpdate(id).withBody(body)
        )
    }

    func delete(_ id: UUID) async throws {
        try await client.requestVoid(APIRoute.reportDelete(id))
    }
}
