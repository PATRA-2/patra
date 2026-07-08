import Observation

@MainActor
@Observable
final class NotificationListViewModel { var items: [NotificationItem] = [] }
