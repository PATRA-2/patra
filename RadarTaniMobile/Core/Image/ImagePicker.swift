import SwiftUI

struct ImagePicker: View {
    var body: some View {
        RTDEmptyStateView(title: "Pilih Foto", message: "Pemilih foto akan dihubungkan ke PhotosPicker.", systemImage: "photo")
    }
}
