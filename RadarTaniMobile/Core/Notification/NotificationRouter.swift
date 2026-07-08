struct NotificationRouter {
    func route(_ notification: NotificationItem) -> HomeTab {
        notification.relatedReportID == nil ? .home : .radarFeed
    }
}
