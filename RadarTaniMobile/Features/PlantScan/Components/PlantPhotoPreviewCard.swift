import SwiftUI

struct PlantPhotoPreviewCard: View {
    let image: UIImage
    let farmName: String
    let crop: String

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 320)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(farmName, systemImage: "leaf.fill")
                        .font(.headline)
                    Text(crop)
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(14)
                .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
                .padding(14)
            }
            .accessibilityLabel("Foto gejala tanaman dari \(farmName)")
    }
}
