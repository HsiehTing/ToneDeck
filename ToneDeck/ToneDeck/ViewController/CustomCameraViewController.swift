//
//  CustomCameraViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/23.
//

// import MijickCameraView
import AVFoundation
import CoreImage
import SwiftUI
import Photos

struct CameraView: View {
    let filterData: [Float?]
    @Binding var path: [CardDestination]
    @ObservedObject private var manager: CameraManager
    weak var delegate: CameraViewControllerDelegate?
    @Environment(\.presentationMode) var presentationMode

    init(filterData: [Float?], path: Binding<[CardDestination]>) {
        self.filterData = filterData
        self._path = path

        let filters = createFilters(from: filterData)
        print(filters)

        self.manager = CameraManager(
            outputType: .photo,
            cameraPosition: .back,
            cameraFilters: filters,
            resolution: .hd4K3840x2160,
            frameRate: 25,
            flashMode: .off,
            isGridVisible: true,
            focusImageColor: .yellow,
            focusImageSize: 92
        )
    }
    var body: some View {
        MCameraController(manager: manager)

            .onImageCaptured { image in
                print("IMAGE CAPTURED")

                PhotoSaver().savePhotoToLibrary(image: image)
                delegate?.didCapturePhoto(image)
            }
            .onVideoCaptured { _ in
                print("VIDEO CAPTURED")
                self.presentationMode.wrappedValue.dismiss()

            }
            .afterMediaCaptured { $0
                .closeCameraController(true)
                .custom { print("Media object has been successfully captured") }
            }
            .onCloseController {
                print("CLOSE THE CONTROLLER")
            }
            .toolbar(.hidden, for: .tabBar)
    }

}

func createFilters(from filterData: [Float?]) -> [CIFilter] {
    // First filter: Color Controls (Brightness, Contrast, Saturation)
    let colorFilter = CIFilter(name: "CIColorControls")!
    let brightnessValue = filterData[0] ?? 0.0
    let contrastValue = filterData[1] ?? 1.0
    let saturationValue = filterData[2] ?? 1.0
    let colorValue = filterData[3] ?? 0.0
    colorFilter.setValue(brightnessValue * 0.7, forKey: kCIInputBrightnessKey)
    colorFilter.setValue(contrastValue * 0.7, forKey: kCIInputContrastKey)
    colorFilter.setValue(saturationValue * 0.7, forKey: kCIInputSaturationKey)
    let hueFilter = CIFilter(name: "CIHueAdjust")!
    hueFilter.setValue(colorValue * 0.7, forKey: kCIInputAngleKey)
    return [hueFilter]
}
class PhotoSaver: NSObject {
    func savePhotoToLibrary(image: UIImage) {

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {

                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                print("Photo library access not granted")
            }
        }
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer?) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image successfully saved to the photo library")
        }
    }
}
