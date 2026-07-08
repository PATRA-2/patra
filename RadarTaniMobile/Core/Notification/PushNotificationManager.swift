import Observation
import UserNotifications

@MainActor
@Observable
final class PushNotificationManager {
    private(set) var isAuthorized = false

    func requestAuthorization() async {
        isAuthorized = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }
}
