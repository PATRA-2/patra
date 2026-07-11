import Foundation
import Observation

@MainActor
@Observable
final class OrderListViewModel {
    private(set) var orders: [PesticideOrderOut] = []
    private(set) var relatedReports: [PlantReportOut] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let ordersService: OrderService
    private let reportService: ReportService
    init(env: AppEnvironment) {
        self.ordersService = env.orders
        self.reportService = env.reports
    }

    func load() async {
        isLoading = true; defer { isLoading = false }
        do {
            async let orderPage = ordersService.list(page: 1, pageSize: 100)
            async let reportPage = reportService.list(page: 1, pageSize: 100)
            let (loadedOrders, loadedReports) = try await (orderPage, reportPage)
            orders = loadedOrders.items
            relatedReports = loadedReports.items
        } catch {
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
