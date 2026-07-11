import Foundation

struct OrderService: Sendable {
    let client: APIClient

    func list(page: Int = 1, pageSize: Int = 20) async throws -> PaginatedList<PesticideOrderOut> {
        try await client.request(PaginatedList<PesticideOrderOut>.self, endpoint: APIRoute.orders(page: page, pageSize: pageSize))
    }
    func create(_ order: PesticideOrderCreate) async throws -> PesticideOrderOut {
        let body = try APICoder.encoder.encode(order)
        return try await client.request(PesticideOrderOut.self, endpoint: APIRoute.ordersCreate.withBody(body))
    }
}