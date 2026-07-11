import Foundation
import Observation

@MainActor
@Observable
final class OrderListViewModel {
    private(set) var orders: [PesticideOrderOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let ordersService: OrderService
    init(env: AppEnvironment) { self.ordersService = env.orders }

    func load() async {
        isLoading = true; defer { isLoading = false }
        do { orders = try await ordersService.list().items } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal memuat pesanan."
        }
    }
    func create(productName: String, quantity: Int, relatedReportId: UUID? = nil) async -> Bool {
        do {
            _ = try await ordersService.create(PesticideOrderCreate(
                productName: productName, quantity: quantity, relatedReportId: relatedReportId))
            await load(); return true
        } catch {
            errorMessage = (error as? APIError)?.userMessage ?? "Gagal membuat pesanan."
            return false
        }
    }
}