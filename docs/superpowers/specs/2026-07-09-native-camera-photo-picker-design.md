# Native Camera and Photo Picker for Plant Report (Tab Lapor)

## Status
Draft — awaiting implementation plan.

## Context
User wants the "Ambil Foto" button on Tab Lapor / PlantScanView to open the native Apple camera/photo picker, allow selecting a source (Camera or Gallery), preview the selected image, and navigate to a new report creation screen.

This is a local-only, UI + permission feature (Scope A). Backend integration, Gemini AI analysis, and Radar Feed publishing are explicitly out of scope for this implementation.

## Goals
1. Tapping "Ambil Foto" opens an action sheet: Kamera or Galeri.
2. Perform manual preflight permission checks for camera / photo library.
3. Open native UIImagePickerController with the chosen source.
4. After photo is captured/selected, save camera photos to the iOS Photo Library.
5. Pass the selected UIImage to a new CreatePlantReportView.
6. Handle denied permissions with an alert offering to open Settings.
7. Keep the implementation reusable for other report types in the future.

## Non-Goals
- Backend upload or AI analysis.
- Multi-photo selection (one photo per report).
- Custom camera UI using AVCaptureSession.
- Saving gallery-selected images to the Photo Library again.

## Architecture

### New Files
- RadarTaniMobile/Services/Image/ImageSelectionService.swift
  Encapsulates permission preflight and Photo Library save operations.
- RadarTaniMobile/Core/Image/ImagePickerCoordinator.swift
  UIViewControllerRepresentable wrapper around UIImagePickerController.
- RadarTaniMobile/Features/PlantScan/Views/CreatePlantReportView.swift
  New report form screen that displays the selected image.
- RadarTaniMobile/Features/PlantScan/Models/PlantReportDraft.swift
  Value object holding title, description, category, and selected image.

### Modified Files
- RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift
  Adds picker/permission/navigation state and coordination methods.
- RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift
  Wires the "Ambil Foto" button to the source sheet, picker, and navigation.

## Data Flow

PlantScanView
  user taps "Ambil Foto"
    showSourceSheet = true
      Action Sheet: Kamera / Galeri
        PlantScanViewModel.selectSource(_:)
          ImageSelectionService.checkPermission(for:)
            denied  -> showPermissionAlert = true
            granted -> imagePickerSourceType set and showImagePicker = true
          ImagePickerCoordinator (sheet)
            UIImagePickerController
              user captures/selects photo
                PlantScanViewModel.selectedImage = UIImage
                if camera source, saveToPhotoLibrary(image)
                navigateToCreateReport = true
                  NavigationLink -> CreatePlantReportView(image)

## State Model

### PlantScanViewModel new state
- selectedImage: UIImage?
- showSourceSheet: Bool = false
- showImagePicker: Bool = false
- imagePickerSourceType: UIImagePickerController.SourceType = .camera
- showPermissionAlert: Bool = false
- navigateToCreateReport: Bool = false
- permissionAlertMessage: String = ""

### PlantReportDraft
- title: String = ""
- description: String = ""
- category: PlantReportCategory = .disease
- image: UIImage?

Note: If a global ReportCategory exists, reuse it. Otherwise define a local PlantReportCategory enum with values .disease, .pest, .other.

## Components

### ImageSelectionService
- checkPermission(for source: UIImagePickerController.SourceType) async -> PermissionStatus
  Checks camera (AVCaptureDevice) or photo library (PHPhotoLibrary) authorization.
- openSettings() opens UIApplication.openSettingsURLString.
- saveImageToPhotoLibrary(_ image: UIImage) async throws saves captured camera photo to the user's library.

### ImagePickerCoordinator
UIViewControllerRepresentable that accepts sourceType and Binding<UIImage?>, presents UIImagePickerController, and dismisses itself after selection or cancellation.

### CreatePlantReportView
- Displays the selected image in a preview area.
- Provides fields for title, description, and category.
- Shows a primary "Simpan Draft" button (disabled until title non-empty).
- No backend call in this scope.

## Error Handling
- If permission is denied or restricted, showPermissionAlert becomes true with a localized message, and an Alert with "Buka Pengaturan" and "Batal" buttons appears.
- Tapping "Buka Pengaturan" calls ImageSelectionService.openSettings().
- If UIImagePickerController reports cancellation, picker simply dismisses without setting selectedImage.

## Testing Checklist
- Tap "Ambil Foto" -> action sheet appears.
- Select Kamera with permission granted -> native camera opens.
- Select Galeri with permission granted -> photo library opens.
- Deny permission -> alert with Settings option appears.
- After capturing/selecting photo -> CreatePlantReportView opens with image preview.
- Camera-captured photos are saved to the iOS Photo Library.
- Gallery-selected photos are NOT saved again.
- Build succeeds on iOS Simulator (camera unavailable on simulator, but galeri bisa diuji via photo library sample).

## Open Questions / Future Work
- Backend upload endpoint will be integrated in a separate task.
- Gemini AI analysis will be added after upload flow is complete.
- Radar Feed publishing remains a future scope item.
