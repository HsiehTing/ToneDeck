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

struct CameraView: View {
    @State private var isFlashOn = false
    @State private var isUsingFrontCamera = false
    @State private var showImagePicker = false
    var body: some View {
        ZStack {           
            VStack {
                // 閃光燈切換按鈕
                HStack {
                    Spacer()
                    Button(action: {
                        isFlashOn.toggle()
                    }) {
                        Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
                
                HStack {
                    // 相簿檢視按鈕
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                    }
                    
                    Spacer()
                    
                    // 快門按鈕
                    Button(action: {
                        // 拍照功能
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.gray, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    
                    Spacer()
                    
                    // 翻轉鏡頭按鈕
                    Button(action: {
                        isUsingFrontCamera.toggle()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker()
        }
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


class CameraViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    var didCapturePhoto: ((UIImage) -> Void)?
    weak var delegate: CameraViewControllerDelegate?
    
    var isUsingFrontCamera = false

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
        
        setupCamera()
        setupUI()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // 預設使用後置鏡頭
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
            let output = AVCapturePhotoOutput()
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer)
            // 在背景執行緒中啟動相機
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera input: \(error)")
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
    
    @objc func shutterButtonTapped() {
        let photoOutput = captureSession.outputs.first as? AVCapturePhotoOutput
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
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
    
    // 將照片保存到相簿
    func savePhotoToLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("保存失敗: \(error.localizedDescription)")
        } else {
            print("saved to your local library")
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
        
        // 自動返回 applycardVC
        dismiss(animated: true, completion: nil)
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}
    


