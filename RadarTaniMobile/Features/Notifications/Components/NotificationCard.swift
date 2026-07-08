import SwiftUI

struct NotificationCard: View {
    let item: NotificationItem
    var body: some View { RTDCard { Text(item.title).font(.headline) } }
}
