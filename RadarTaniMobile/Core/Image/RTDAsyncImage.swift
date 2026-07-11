import SwiftUI

struct RTDAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty: RTDLoadingView()
                case .success(let img): img.resizable().aspectRatio(contentMode: contentMode)
                case .failure: placeholder
                @unknown default: placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(Color(.secondarySystemBackground))
            Image(systemName: "photo").foregroundStyle(.secondary)
        }
    }
}