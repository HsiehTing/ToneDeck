//
//  CameraViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/13.
//

import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    @State private var isFlashOn = false
    @State private var isUsingFrontCamera = false
    @State private var showImagePicker = false
    
    var body: some View {
        ZStack {
            CameraPreview(isUsingFrontCamera: $isUsingFrontCamera, isFlashOn: $isFlashOn)
                .edgesIgnoringSafeArea(.all)
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


struct CameraPreview: UIViewControllerRepresentable {
    @Binding var isUsingFrontCamera: Bool
    @Binding var isFlashOn: Bool
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.setupCamera(isFront: isUsingFrontCamera, flashOn: isFlashOn)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.toggleCamera(isFront: isUsingFrontCamera)
        uiViewController.toggleFlash(flashOn: isFlashOn)
    }
}

class CameraViewController: UIViewController {
    private var captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var currentCamera: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera(isFront: false, flashOn: false)
    }
    
    func setupCamera(isFront: Bool, flashOn: Bool) {
        captureSession.beginConfiguration()
        
        // 選擇相機
        let camera = isFront ? getCamera(position: .front) : getCamera(position: .back)
        currentCamera = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error setting up camera input: \(error)")
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        captureSession.startRunning()
    }
    
    func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.devices(for: .video).first { $0.position == position }
    }
    
    func toggleCamera(isFront: Bool) {
        captureSession.stopRunning()
        setupCamera(isFront: isFront, flashOn: false)
        captureSession.startRunning()
    }
    
    func toggleFlash(flashOn: Bool) {
        guard let currentCamera = currentCamera, currentCamera.hasFlash else { return }
        do {
            try currentCamera.lockForConfiguration()
            currentCamera.flashMode = flashOn ? .on : .off
            currentCamera.unlockForConfiguration()
        } catch {
            print("Error setting flash: \(error)")
        }
    }
}
