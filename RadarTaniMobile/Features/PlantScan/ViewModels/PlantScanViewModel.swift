import Observation
import UIKit

@MainActor
@Observable
final class PlantScanViewModel {
    let activeFarm = Farm(name: "Sawah Utara", crop: "Padi", location: "Desa Sukamaju", isActive: true)
    let tips = [
        "Foto tanaman yang menunjukkan gejala tidak biasa.",
        "Ambil gambar daun atau batang dengan pencahayaan jelas.",
        "Hasil AI dapat dibagikan sebagai laporan ke Radar Feed."
    ]

    var selectedImage: UIImage?
    var showSourceSheet = false
    var showImagePicker = false
    var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    var showPermissionAlert = false
    var navigateToCreateReport = false
    var permissionAlertMessage = ""

    private let imageSelectionService = ImageSelectionService()

    func didTapAmbilFoto() {
        showSourceSheet = true
    }

    func selectSource(_ source: UIImagePickerController.SourceType) {
        imagePickerSourceType = source
        showSourceSheet = false

        Task {
            let status = await imageSelectionService.checkPermission(for: source)
            await handlePermissionStatus(status, source: source)
        }
    }

    func didPickImage(_ image: UIImage?) {
        guard let image else { return }
        selectedImage = image

        if imagePickerSourceType == .camera {
            Task {
                try? await imageSelectionService.saveImageToPhotoLibrary(image)
            }
        }

        navigateToCreateReport = true
    }

    func openSettings() {
        Task {
            await imageSelectionService.openSettings()
        }
    }

    private func handlePermissionStatus(_ status: PermissionStatus, source: UIImagePickerController.SourceType) async {
        switch status {
        case .authorized:
            showImagePicker = true
        case .denied, .restricted:
            permissionAlertMessage = permissionMessage(for: source)
            showPermissionAlert = true
        case .notDetermined:
            break
        }
    }

    private func permissionMessage(for source: UIImagePickerController.SourceType) -> String {
        switch source {
        case .camera:
            return "Izin kamera diperlukan untuk mengambil foto. Buka Pengaturan untuk memberikan izin."
        case .photoLibrary, .savedPhotosAlbum:
            return "Izin galeri diperlukan untuk memilih foto. Buka Pengaturan untuk memberikan izin."
        @unknown default:
            return "Izin diperlukan untuk melanjutkan. Buka Pengaturan untuk memberikan izin."
        }
    }
}
