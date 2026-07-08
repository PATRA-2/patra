struct NotificationService: Sendable {
    func notifications() async -> [NotificationItem] { [] }
}
