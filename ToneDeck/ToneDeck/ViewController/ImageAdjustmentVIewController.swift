//
//  ImageAdjustmentVIewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/20.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import FirebaseStorage
import Firebase
import Photos

struct ImageAdjustmentView: View {
    @State private var brightness: Float = 0.0
    @State private var contrast: Float = 1.0
    @State private var saturation: Float = 1.0
    @State private var hueAdjustment: Float = 0.0

    @State private var card: Card

    @State private var adjustedImage: UIImage?
    let originalImage: UIImage

    var body: some View {
        VStack {
            // Display the adjusted image
            if let adjustedImage = adjustedImage {
                Image(uiImage: adjustedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()

                            saveFilteredImageToLibrary()
                            addPhotoData()
            }

            // Sliders for adjusting brightness, contrast, and saturation
            VStack {
                Text("Brightness: \(brightness)")
                Slider(value: Binding(get: {
                    Double(self.brightness)
                }, set: { newValue in
                    self.brightness = Float(newValue)
                    self.applyAdjustments()
                }), in: -1.0...1.0)

                Text("Contrast: \(contrast)")
                Slider(value: Binding(get: {
                    Double(self.contrast)
                }, set: { newValue in
                    self.contrast = Float(newValue)
                    self.applyAdjustments()
                }), in: 0.5...2.0)

                Text("Saturation: \(saturation)")
                Slider(value: Binding(get: {
                    Double(self.saturation)
                }, set: { newValue in
                    self.saturation = Float(newValue)
                    self.applyAdjustments()
                }), in: 0.0...2.0)

                Text("Hue Adjustment: \(hueAdjustment)")
                Slider(value: Binding(get: {
                    Float(self.hueAdjustment)
                }, set: { newValue in
                    self.hueAdjustment = Float(newValue)
                    self.applyAdjustments()
                }), in: -Float.pi...Float.pi)
            }
            .padding()
        }
        .onAppear {
            // Initially apply adjustments using default values
            applyAdjustments()
        }
    }

    // Function to apply filters and update the image
    private func applyAdjustments() {
        adjustedImage = applyImageAdjustments(
            image: originalImage,
            smoothValues: [brightness, contrast, saturation],
            hueAdjustment: hueAdjustment
        )
    }
    func addPhotoData() {
        guard let image = adjustedImage else {
            print("cant find target image")
            return
        }
        let cardID = card.id
        let createdTime = Date()
        let defaults = UserDefaults.standard
        let creatorID = defaults.string(forKey: "userDocumentID")
        guard let imageData = image.jpegData(compressionQuality: 0.8)
        else {
            print("Unable to get image data")
            return
        }
        let storageRef = Storage.storage().reference().child("photo/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metaData, error in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting image URL: \(error)")
                    return
                }
                if let imageURL = url?.absoluteString {
                    let db = Firestore.firestore()
                    let photos = Firestore.firestore().collection("photos")
                    let document = photos.document()
                    let photoData: [String: Any] = [
                        "id": document.documentID,
                        "cardID": cardID ?? "",
                        "createdTime": createdTime,
                        "imageURL": imageURL,
                        "creatorID": creatorID ?? ""
                    ]
                   document.setData(photoData) {error in
                        if let error = error {
                            print("error saving photo data \(error)")
                        } else {
                            print("photo successfully saved!")
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    func saveFilteredImageToLibrary() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async {
                    guard let image = self.targetImageView.image else { return }
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
            }
        }
    }
}

// Function to apply filters to the image
func applyImageAdjustments(image: UIImage, smoothValues: [Float], hueAdjustment: Float) -> UIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }

    // Apply brightness, contrast, and saturation adjustments
    let colorControlsFilter = CIFilter(name: "CIColorControls")
    colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
    colorControlsFilter?.setValue(smoothValues[0], forKey: kCIInputBrightnessKey)
    colorControlsFilter?.setValue(smoothValues[1], forKey: kCIInputContrastKey)
    colorControlsFilter?.setValue(smoothValues[2], forKey: kCIInputSaturationKey)
    guard let colorControlsOutput = colorControlsFilter?.outputImage else { return nil }

    // Apply hue adjustment
    let hueAdjustFilter = CIFilter(name: "CIHueAdjust")
    hueAdjustFilter?.setDefaults()
    hueAdjustFilter?.setValue(colorControlsOutput, forKey: kCIInputImageKey)
    hueAdjustFilter?.setValue(hueAdjustment, forKey: kCIInputAngleKey)
    guard let hueAdjustOutput = hueAdjustFilter?.outputImage else { return nil }

    // Create final UIImage
    let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
    guard let cgImage = context.createCGImage(hueAdjustOutput, from: hueAdjustOutput.extent) else { return nil }

    return UIImage(cgImage: cgImage)
}

