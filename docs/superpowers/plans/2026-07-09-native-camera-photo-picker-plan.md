
# Native Camera and Photo Picker for Plant Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Wire the Ambil Foto button on Tab Lapor to native Apple camera/photo picker, preview the selected image, and navigate to a new local report creation screen.

**Architecture:** Use a reusable ImageSelectionService for permission preflight and Photo Library saves, a UIViewControllerRepresentable (ImagePickerCoordinator) wrapping UIImagePickerController, and extend PlantScanViewModel to coordinate source selection, picker presentation, and navigation to CreatePlantReportView.

**Tech Stack:** SwiftUI, UIKit (UIImagePickerController), AVFoundation (camera permission), Photos (photo library permission), Observation (@Observable).

## Global Constraints
- Target iOS version floor follows the existing Xcode project.
- Use existing design system colors and components (PrimaryButtonStyle, RTDColor, rtdCard, RTDTextField).
- Keep backend/AI integration out of scope.
- One photo per report.
- Save camera-captured photos to the iOS Photo Library; do not re-save gallery-selected photos.
- Handle denied permissions with an alert that offers to open Settings.
- Do not modify CameraPicker.swift or ImagePicker.swift placeholders if they are used elsewhere; leave them intact.

---

## File Map

### New Files
- RadarTaniMobile/Services/Image/ImageSelectionService.swift - permission preflight, Settings URL, Photo Library save.
- RadarTaniMobile/Core/Image/ImagePickerCoordinator.swift - UIViewControllerRepresentable for camera/photo picker.
- RadarTaniMobile/Features/PlantScan/Models/PlantReportDraft.swift - value object for form state.
- RadarTaniMobile/Features/PlantScan/Views/CreatePlantReportView.swift - form + preview screen.

### Modified Files
- RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift - add picker/permission/navigation state and helper methods.
- RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift - wire button, action sheet, picker sheet, alert, and navigation link.
- RadarTaniMobile/SupportingFiles/Info.plist - add NSCameraUsageDescription and NSPhotoLibraryUsageDescription.

---

### Task 1: Add Camera and Photo Library Permission Strings

**Files:**
- Modify: RadarTaniMobile/SupportingFiles/Info.plist
- Test: Build app; no runtime assertion for missing usage strings.

**Interfaces:**
- Consumes: none.
- Produces: NSCameraUsageDescription and NSPhotoLibraryUsageDescription entries in Info.plist.

- [ ] **Step 1: Open the existing Info.plist**

Read RadarTaniMobile/SupportingFiles/Info.plist.

- [ ] **Step 2: Add the usage description strings**

Insert these two entries if not already present:

```xml
<key>NSCameraUsageDescription</key>
<string>Kamera digunakan untuk mengambil foto tanaman sebagai laporan.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Akses galeri digunakan untuk memilih foto tanaman dari perangkat.</string>
```

- [ ] **Step 3: Verify build succeeds**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' clean build
```

Expected: build succeeds with no Missing Info.plist value warnings.

- [ ] **Step 4: Commit**

```bash
git add RadarTaniMobile/SupportingFiles/Info.plist
git commit -m "chore: add camera and photo library usage descriptions"
```

---

### Task 2: Create ImageSelectionService

**Files:**
- Create: RadarTaniMobile/Services/Image/ImageSelectionService.swift
- Test: Build app after creation; manual test on device/simulator for permission paths.

**Interfaces:**
- Consumes: AVCaptureDevice, PHPhotoLibrary, UIApplication.
- Produces:
  - enum PermissionStatus: Sendable { case authorized, denied, restricted, notDetermined }
  - actor ImageSelectionService
  - func checkPermission(for source: UIImagePickerController.SourceType) async -> PermissionStatus
  - func openSettings()
  - func saveImageToPhotoLibrary(_ image: UIImage) async throws

- [ ] **Step 1: Write the service file**

Create RadarTaniMobile/Services/Image/ImageSelectionService.swift with the following content:

```swift
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

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            return
        }
        Task { @MainActor in
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
```

- [ ] **Step 2: Verify build succeeds**

Run the same xcodebuild command as Task 1.

Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add RadarTaniMobile/Services/Image/ImageSelectionService.swift
git commit -m "feat: add image selection service for permission and photo save"
```


---

### Task 3: Create ImagePickerCoordinator

**Files:**
- Create: RadarTaniMobile/Core/Image/ImagePickerCoordinator.swift
- Test: Build app after creation; manual test on device/simulator.

**Interfaces:**
- Consumes: UIImagePickerController.SourceType, Binding<UIImage?>.
- Produces: struct ImagePickerCoordinator: UIViewControllerRepresentable.

- [ ] **Step 1: Write the coordinator file**

Create RadarTaniMobile/Core/Image/ImagePickerCoordinator.swift with the following content:

```swift
import SwiftUI
import UIKit

struct ImagePickerCoordinator: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerCoordinator

        init(_ parent: ImagePickerCoordinator) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

- [ ] **Step 2: Verify build succeeds**

Run the same xcodebuild command as Task 1.

Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add RadarTaniMobile/Core/Image/ImagePickerCoordinator.swift
git commit -m "feat: add image picker coordinator for camera and photo library"
```

---

### Task 4: Create PlantReportDraft Model

**Files:**
- Create: RadarTaniMobile/Features/PlantScan/Models/PlantReportDraft.swift
- Test: Build app after creation.

**Interfaces:**
- Consumes: none.
- Produces: struct PlantReportDraft with title, description, category, image.

- [ ] **Step 1: Write the model file**

Create RadarTaniMobile/Features/PlantScan/Models/PlantReportDraft.swift with the following content:

```swift
import UIKit

enum PlantReportCategory: String, CaseIterable, Identifiable {
    case disease = "Penyakit"
    case pest = "Hama"
    case other = "Lainnya"

    var id: String { rawValue }
}

struct PlantReportDraft {
    var title: String = ""
    var description: String = ""
    var category: PlantReportCategory = .disease
    var image: UIImage?
}
```

- [ ] **Step 2: Verify build succeeds**

Run the same xcodebuild command as Task 1.

Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add RadarTaniMobile/Features/PlantScan/Models/PlantReportDraft.swift
git commit -m "feat: add plant report draft model"
```


---

### Task 5: Extend PlantScanViewModel with Picker State and Coordination

**Files:**
- Modify: RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift
- Test: Build app after modification; manual test on device/simulator.

**Interfaces:**
- Consumes: ImageSelectionService, ImagePickerCoordinator.SourceType, PermissionStatus.
- Produces: PlantScanViewModel with new state and methods.

- [ ] **Step 1: Replace the existing file content**

Replace the entire contents of RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift with:

```swift
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
        imageSelectionService.openSettings()
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
```

- [ ] **Step 2: Verify build succeeds**

Run the same xcodebuild command as Task 1.

Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add RadarTaniMobile/Features/PlantScan/ViewModels/PlantScanViewModel.swift
git commit -m "feat: extend plant scan view model with image selection state"
```


---

### Task 6: Create CreatePlantReportView

**Files:**
- Create: RadarTaniMobile/Features/PlantScan/Views/CreatePlantReportView.swift
- Test: Build app after creation; manual test on device/simulator.

**Interfaces:**
- Consumes: UIImage, PlantReportDraft, PrimaryButtonStyle, RTDColor, RTDTextField, rtdCard.
- Produces: struct CreatePlantReportView: View.

- [ ] **Step 1: Write the view file**

Create RadarTaniMobile/Features/PlantScan/Views/CreatePlantReportView.swift with the following content:

```swift
import SwiftUI

struct CreatePlantReportView: View {
    let image: UIImage
    @State private var draft = PlantReportDraft()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Detail Laporan")
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)

                    RTDTextField(title: "Judul", text: $draft.title)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kategori")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                        Picker("Kategori", selection: $draft.category) {
                            ForEach(PlantReportCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Deskripsi")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTDColor.textSecondary)
                        TextEditor(text: $draft.description)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(RTDColor.mutedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(18)
                .rtdCard()

                Button {
                    // Local save only for this scope.
                    dismiss()
                } label: {
                    Label("Simpan Draft", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(draft.title.isEmpty)
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Buat Laporan")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

- [ ] **Step 2: Verify build succeeds**

Run the same xcodebuild command as Task 1.

Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add RadarTaniMobile/Features/PlantScan/Views/CreatePlantReportView.swift
git commit -m "feat: add create plant report view with image preview"
```


---

### Task 7: Wire PlantScanView with Action Sheet, Picker, Alert, and Navigation

**Files:**
- Modify: RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift
- Test: Build app after modification; manual test on device/simulator.

**Interfaces:**
- Consumes: PlantScanViewModel, ImagePickerCoordinator, CreatePlantReportView.
- Produces: Updated PlantScanView with full camera/photo flow.

- [ ] **Step 1: Replace the existing file content**

Replace the entire contents of RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift with:

```swift
import SwiftUI

struct PlantScanView: View {
    @State private var viewModel = PlantScanViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FarmSelectorPill(farmName: viewModel.activeFarm.name, crop: viewModel.activeFarm.crop)

                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [RTDColor.deepGreen, RTDColor.leafGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "camera.macro")
                        .font(.system(size: 150))
                        .foregroundStyle(.white.opacity(0.12))
                        .offset(x: 120, y: -20)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lapor")
                            .font(.system(size: 32, weight: .bold))
                        Text("Foto gejala tanaman, dapatkan analisis AI, lalu bagikan ke Radar Feed.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.84))
                        Button {
                            viewModel.didTapAmbilFoto()
                        } label: {
                            Label("Ambil Foto", systemImage: "camera.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 10)
                    }
                    .foregroundStyle(.white)
                    .padding(24)
                }
                .frame(minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                    Text("Panduan Laporan")
                        .font(.headline)
                        .foregroundStyle(RTDColor.textPrimary)
                    ForEach(viewModel.tips, id: \.self) { tip in
                        Label(tip, systemImage: "checkmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(RTDColor.textSecondary)
                    }
                }
                .padding(18)
                .rtdCard()
            }
            .padding(20)
        }
        .background(RTDColor.background)
        .navigationTitle("Lapor")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Pilih Sumber Foto", isPresented: $viewModel.showSourceSheet, titleVisibility: .visible) {
            Button("Kamera") {
                viewModel.selectSource(.camera)
            }
            Button("Galeri") {
                viewModel.selectSource(.photoLibrary)
            }
            Button("Batal", role: .cancel) {}
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePickerCoordinator(
                sourceType: viewModel.imagePickerSourceType,
                selectedImage: Binding(
                    get: { viewModel.selectedImage },
                    set: { viewModel.didPickImage($0) }
                )
            )
        }
        .alert("Izin Diperlukan", isPresented: $viewModel.showPermissionAlert) {
            Button("Batal", role: .cancel) {}
            Button("Buka Pengaturan") {
                viewModel.openSettings()
            }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
        .navigationDestination(isPresented: $viewModel.navigateToCreateReport) {
            if let image = viewModel.selectedImage {
                CreatePlantReportView(image: image)
            }
        }
    }
}
```

- [ ] **Step 2: Verify build succeeds**

Run the same xcodebuild command as Task 1.

Expected: build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add RadarTaniMobile/Features/PlantScan/Views/PlantScanView.swift
git commit -m "feat: wire ambil foto button to camera/gallery picker and report view"
```


---

### Task 8: Final Build and Manual Smoke Test

**Files:**
- Test: Entire app flow.

**Interfaces:**
- Consumes: all tasks above.
- Produces: working app build.

- [ ] **Step 1: Full clean build**

Run:

```bash
xcodebuild -project RadarTaniMobile.xcodeproj -scheme RadarTaniMobile -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' clean build
```

Expected: build succeeds with no errors or warnings.

- [ ] **Step 2: Manual smoke test on simulator**

1. Launch app on iPhone 16 simulator.
2. Navigate to Tab Lapor.
3. Tap "Ambil Foto".
4. Confirm action sheet shows "Kamera" and "Galeri".
5. Tap "Galeri" (photo library is testable on simulator; camera is not).
6. Select a photo from the library.
7. Confirm CreatePlantReportView opens with the selected image preview.
8. Fill in title, choose category, add description, tap "Simpan Draft".

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "feat: complete native camera and photo picker for plant report"
```

---

## Spec Coverage Check
- Goal 1 (action sheet) -> Task 7.
- Goal 2 (preflight permission) -> Task 2 + Task 5.
- Goal 3 (native picker) -> Task 3 + Task 7.
- Goal 4 (save camera photo) -> Task 2 + Task 5.
- Goal 5 (pass image to CreatePlantReportView) -> Task 4 + Task 6 + Task 7.
- Goal 6 (permission alert) -> Task 5 + Task 7.
- Goal 7 (reusable) -> Task 2 + Task 3 architecture.

## Placeholder Scan
No TBD, TODO, or "implement later" markers. All code blocks are complete. All file paths are exact. All test commands include expected output.

## Type Consistency Check
- PermissionStatus is defined in Task 2 and used in Task 5.
- ImageSelectionService is an actor, called with await in Task 5.
- ImagePickerCoordinator.SourceType matches UIImagePickerController.SourceType.
- PlantReportCategory is defined in Task 4 and used in Task 6.
- PlantReportDraft is created in Task 4 and used in Task 6.
