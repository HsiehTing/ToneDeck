//
//  CameraViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/13.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject var cameraModel = CameraModel()
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(cameraModel: cameraModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    // Left: Album Button
                    Button(action: {
                        cameraModel.showPhotoPicker = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                    
                    // Right: Flash Button
                    Button(action: {
                        cameraModel.toggleFlash()
                    }) {
                        Image(systemName: cameraModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
                
                HStack {
                    // Right: Flip Camera Button
                    Spacer()
                    Button(action: {
                        cameraModel.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                // Middle: Shutter Button
                HStack {
                    Spacer()
                    Button(action: {
                        cameraModel.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 5)
                            .frame(width: 70, height: 70)
                            .padding(.bottom)
                    }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $cameraModel.showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $cameraModel.selectedImage)
        }
    }
}

// Camera Model for managing camera interactions
class CameraModel: ObservableObject {
    @Published var isFlashOn = false
    @Published var showPhotoPicker = false
    @Published var selectedImage: UIImage?
    
    private var captureSession = AVCaptureSession()
    private var currentCamera: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    
    init() {
        setupCamera()
    }
    
    func setupCamera() {
        captureSession.beginConfiguration()
        
        // Setup camera device
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            currentCamera = camera
            let input = try! AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        
        // Toggle between front and back camera
        let newCameraPosition: AVCaptureDevice.Position = (currentCamera?.position == .back) ? .front : .back
        if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition) {
            currentCamera = newCamera
            let newInput = try! AVCaptureDeviceInput(device: newCamera)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        }
        
        captureSession.commitConfiguration()
    }
}

// Camera Preview for displaying the camera feed
struct CameraPreview: UIViewRepresentable {
    let cameraModel: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraModel.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// ImagePicker for photo library access
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
