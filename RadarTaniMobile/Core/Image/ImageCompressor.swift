import UIKit

enum ImageCompressor {
    static func jpegData(from image: UIImage, quality: CGFloat = 0.82) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}
