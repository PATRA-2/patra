import UIKit
import AVFoundation
import Photos

enum PermissionStatus: Sendable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

actor ImageSelectionService {
    func checkPermission(for source: UIImagePickerController.SourceType) async -> PermissionStatus {
        switch source {
        case .camera:
            return await requestCameraPermission()
        case .photoLibrary, .savedPhotosAlbum:
            return await requestPhotoLibraryPermission()
        @unknown default:
            return .denied
        }
    }

    func openSettings() async {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        await MainActor.run {
            guard UIApplication.shared.canOpenURL(settingsURL) else { return }
            UIApplication.shared.open(settingsURL)
        }
    }

    func saveImageToPhotoLibrary(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private func requestCameraPermission() async -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }

    private func requestPhotoLibraryPermission() async -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return (newStatus == .authorized || newStatus == .limited) ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }
}
