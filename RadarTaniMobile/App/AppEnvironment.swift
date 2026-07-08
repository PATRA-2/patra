struct AppEnvironment {
    let authService: AuthService
    let farmService: FarmService
    let aiService: AIService
    let reportService: ReportService
    let notificationService: NotificationService
    let uploadService: UploadService

    static let mock = AppEnvironment(
        authService: AuthService(),
        farmService: FarmService(),
        aiService: AIService(),
        reportService: ReportService(),
        notificationService: NotificationService(),
        uploadService: UploadService()
    )
}
