import Foundation

struct FarmService: Sendable {
    let client: APIClient

    func farms(page: Int = 1, pageSize: Int = 20) async throws -> PaginatedList<FarmOut> {
        try await client.request(PaginatedList<FarmOut>.self, endpoint: APIRoute.farms(page: page, pageSize: pageSize))
    }
    func create(_ farm: FarmCreate) async throws -> FarmOut {
        let body = try APICoder.encoder.encode(farm)
        return try await client.request(FarmOut.self, endpoint: APIRoute.farmsCreate.withBody(body))
    }
    func update(_ id: UUID, _ farm: FarmUpdate) async throws -> FarmOut {
        let body = try APICoder.encoder.encode(farm)
        return try await client.request(FarmOut.self, endpoint: APIRoute.farmUpdate(id).withBody(body))
    }
    func delete(_ id: UUID, force: Bool = false) async throws {
        try await client.requestVoid(APIRoute.farmDelete(id, force: force))
    }
}
