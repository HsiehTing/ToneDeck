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
    @Environment(\.presentationMode) var presentationMode
    @State private var brightness: Float = 0.0
    @State private var contrast: Float = 1.0
    @State private var saturation: Float = 1.0
    @State private var hueAdjustment: Float = 0.0

    @State var card: Card

    @State private var adjustedImage: UIImage?
    let originalImage: UIImage
    let saveToLibrary = SaveToLibrary()

    var body: some View {
        VStack {
            // Display the adjusted image
            if let adjustedImage = adjustedImage {
                Image(uiImage: adjustedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()

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
            Button(action: {
                if let image = adjustedImage {
                    saveToLibrary.saveImageToPhotoLibrary(image: image, card: card)
                    saveToLibrary.addPhotoData(image: image, card: card)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Save Image")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
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

class SaveToLibrary {
    func addPhotoData(image: UIImage, card: Card) {

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

                        }
                    }
                }
            }
        }
    }
    func saveImageToPhotoLibrary(image: UIImage, card: Card) {
        // 請求相簿存取權限
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // 在 Photo Library 的改動要包在 performChanges 之內
                PHPhotoLibrary.shared().performChanges({
                    // 創建圖片資產請求
                    let creationRequest = PHAssetCreationRequest.creationRequestForAsset(from: image)

                    // 選擇保存到相簿（如果需要特定相簿，可以在這裡指定）
                    let albumTitle = card.cardName
                    self.addImageToCustomAlbum(creationRequest, albumTitle: albumTitle)

                }) { success, error in
                    // 處理結果
                    if success {
                        print("照片已保存到相簿")
                    } else if let error = error {
                        print("保存失敗: \(error.localizedDescription)")
                    }
                }
            } else {
                print("沒有權限存取相簿")
            }
        }
    }

    // 保存到自定義相簿
    func addImageToCustomAlbum(_ creationRequest: PHAssetCreationRequest, albumTitle: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)

        // 搜索是否已經有這個相簿
        let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject

        if let album = album {
            // 已經有這個相簿，直接添加圖片
            let assetPlaceholder = creationRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
        } else {
            // 創建一個新的相簿，並添加圖片
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { success, error in
                if success {
                    print("自定義相簿已創建並添加照片")
                } else if let error = error {
                    print("創建相簿失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

