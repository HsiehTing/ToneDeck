//
//  NoFilterCameraView.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/24.
//

import MijickCameraView
import AVFoundation
import CoreImage
import SwiftUI
import Photos

struct NoFilterCameraView: View {
    var onCapture: (UIImage) -> Void
    @ObservedObject private var manager: CameraManager
    weak var delegate: CameraViewControllerDelegate?
    @Environment(\.presentationMode) var presentationMode

    // 更新 init 方法，將 path 參數也加入初始化
    init(onCapture: @escaping (UIImage) -> Void) {
        self.onCapture = onCapture
        self.manager = CameraManager(
            outputType: .photo,
            cameraPosition: .back,
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
                onCapture(image)
                delegate?.didCapturePhoto(image)
                self.presentationMode.wrappedValue.dismiss()
            }
            .onVideoCaptured { url in
                print("VIDEO CAPTURED")
            }
            .afterMediaCaptured { $0
                .closeCameraController(true)
                .custom { print("Media object has been successfully captured") }
            }
            .onCloseController {
                print("CLOSE THE CONTROLLER")


            }
    }
}
