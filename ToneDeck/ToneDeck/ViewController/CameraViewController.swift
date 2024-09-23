//
//  CameraViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/13.
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct CameraViewControllerWrapper: UIViewControllerRepresentable {
    let card: Card

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController()
        cameraVC.filterData = card.filterData
        return cameraVC
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the view controller if needed
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
        }
    }
}


class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    var ciContext: CIContext!
    var colorFilter: CIFilter!
    var hueFilter: CIFilter!
    var didCapturePhoto: ((UIImage) -> Void)?
    weak var delegate: CameraViewControllerDelegate?
    var filterData: [Float]? = nil
    var previewImageView = UIImageView()
    var isUsingFrontCamera = false
    var capturedImage: CIImage? // 用來存儲捕捉的影像

    // 快門按鈕
    let shutterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📸", for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 35
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // 翻轉相機按鈕
    let flipCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🔄", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
         previewImageView = UIImageView(frame: view.bounds)
            previewImageView.contentMode = .scaleAspectFill
            view.addSubview(previewImageView)
        setupCamera()
        setupUI()
        setupFilter()
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(flipCameraTapped), for: .touchUpInside)
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        captureDevice = getCameraDevice(position: .back)
        guard let captureDevice = captureDevice else {
            print("無法訪問相機")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraFrameProcessingQueue"))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera input: \(error)")
        }
    }

    func setupFilter() {
        ciContext = CIContext()
        colorFilter = CIFilter(name: "CIColorControls")
        hueFilter = CIFilter(name: "CIHueAdjust")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 獲取影像數據
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // 應用濾鏡
        applyFilters(to: ciImage) { filteredCIImage in
            if let filteredCIImage = filteredCIImage {
                DispatchQueue.main.async {
                    // 創建一個 CGImage，將它呈現在 UIImageView 或其他預覽層上
                    if let cgImage = self.ciContext.createCGImage(filteredCIImage, from: filteredCIImage.extent) {
                           let processedUIImage = UIImage(cgImage: cgImage)
                           self.previewImageView.image = processedUIImage
                       }
                }
            }
        }
    }

    func setupUI() {
            // 添加快門按鈕
            view.addSubview(shutterButton)
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            shutterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
            shutterButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
            shutterButton.heightAnchor.constraint(equalToConstant: 70).isActive = true
            shutterButton.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)

            // 添加翻轉相機按鈕
            view.addSubview(flipCameraButton)
            flipCameraButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
            flipCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
            flipCameraButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
            flipCameraButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            flipCameraButton.addTarget(self, action: #selector(flipCameraTapped), for: .touchUpInside)
        }

    func applyFilters(to ciImage: CIImage, completion: @escaping (CIImage?) -> Void) {
        colorFilter.setValue(ciImage, forKey: kCIInputImageKey)
        colorFilter.setValue(filterData?[0], forKey: kCIInputBrightnessKey)
        colorFilter.setValue(filterData?[1], forKey: kCIInputContrastKey)
        colorFilter.setValue(filterData?[2], forKey: kCIInputSaturationKey)

        guard let colorFilteredImage = colorFilter.outputImage else {
            completion(nil)
            return
        }

        hueFilter.setValue(colorFilteredImage, forKey: kCIInputImageKey)
        hueFilter.setValue(filterData?[3], forKey: kCIInputAngleKey)

        guard let finalFilteredImage = hueFilter.outputImage else {
               completion(nil)
               return
           }
        completion(finalFilteredImage)

    }

    @objc func shutterButtonTapped() {
        guard let ciImage = capturedImage else {
            print("沒有捕獲到影像")
            return
        }

        // 應用濾鏡到拍照結果
        applyFilters(to: ciImage) { [weak self] filteredImage in
            guard let self = self, let filteredImage = filteredImage else { return }

            // 保存到相簿
            self.savePhotoToLibrary(image: UIImage(ciImage: filteredImage) )

            // 通知代理拍照完成
            self.delegate?.didCapturePhoto(UIImage(ciImage: filteredImage))

            // 自動返回前一個畫面
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc func flipCameraTapped() {
        captureSession.beginConfiguration()
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            return
        }
        captureSession.removeInput(currentInput)
        isUsingFrontCamera.toggle()
        captureDevice = getCameraDevice(position: isUsingFrontCamera ? .front : .back)
        do {
            let newInput = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        } catch {
            print("Error switching camera: \(error)")
        }
        captureSession.commitConfiguration()
    }

    func getCameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        return devices.first { $0.position == position }
    }

    func savePhotoToLibrary(image: UIImage) {
        // Request authorization to access the photo library
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Save the image to the photo library
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                print("Photo library access not granted")
            }
        }
    }

    // Callback to handle success or error after saving
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image successfully saved to the photo library")
        }
    }

}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        // 將照片保存到相簿
        savePhotoToLibrary(image: image)

        delegate?.didCapturePhoto(image)

        // 自動返回到前一個畫面
        dismiss(animated: true, completion: nil)
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}


