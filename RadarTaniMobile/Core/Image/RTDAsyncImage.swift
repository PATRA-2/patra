import SwiftUI

struct RTDAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var resolvedURL: URL? {
        guard let urlString = url else { return nil }
        let fixed = urlString
            .replacingOccurrences(of: "http://127.0.0.1:8000", with: "https://patra-api.kamil.my.id")
            .replacingOccurrences(of: "http://localhost:8000", with: "https://patra-api.kamil.my.id")
        return URL(string: fixed)
    }

    var body: some View {
        if let url = resolvedURL {
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