struct NotificationRouter {
    func route(_ notification: NotificationItem) -> HomeTab {
        notification.relatedReportId == nil ? .home : .radarFeed
    }
}
