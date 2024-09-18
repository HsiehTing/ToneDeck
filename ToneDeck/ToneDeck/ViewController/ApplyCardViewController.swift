//
//  ApplyCardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/13.
//

import SwiftUI
import UIKit
import PhotosUI
import CoreImage
import FirebaseStorage
import Firebase

struct ApplyCardViewControllerWrapper: UIViewControllerRepresentable {
    let card: Card
    func makeUIViewController(context: Context) -> ApplyCardViewController {
        let viewController = ApplyCardViewController()
        viewController.card = card
        return viewController
    }
    func updateUIViewController(_ uiViewController: ApplyCardViewController, context: Context) {}
}

// UIKit ViewController (ApplyCardViewController)
class ApplyCardViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraViewControllerDelegate {
    var card: Card?
    let imageView = UIImageView()
    let targetImageView = UIImageView()
    var filterImage = UIImage()
    let applyButton = UIButton()
    let cameraButton = UIButton(type: .system)
    let histogram = ImageHistogramCalculator()
    var targetImage: UIImage? // 用來保存選取的圖片
    var tBrightness: Float = 1  // 較平滑的亮度變化
    var tContrast: Float = 1    // 中等強度的對比度變化
    var tSaturation: Float = 1  // 更強的飽和度變化
    var scaledValues: [Float]?
    var colorVector: [Float] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Configure the card imageView and label
        if let card = card {
            imageView.kf.setImage(with: URL(string: card.imageURL))
            filterImage = imageView.image ?? UIImage()
            let nameLabel = UILabel()
            nameLabel.text = card.cardName
            nameLabel.textColor = .white
            nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            view.addSubview(imageView)
            view.addSubview(nameLabel)
            view.addSubview(applyButton)
            // Layout card imageView and label
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                imageView.heightAnchor.constraint(equalToConstant: 200),
                nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
                nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
            ])
        }
        // Configure the target imageView for photo selection
        targetImageView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        targetImageView.contentMode = .scaleAspectFit
        targetImageView.image = UIImage(systemName: "camera")
        targetImageView.tintColor = .white
        targetImageView.isUserInteractionEnabled = true
        view.addSubview(targetImageView)
        // Add gesture to open options
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(targetImageTapped))
        targetImageView.addGestureRecognizer(tapGesture)
        // Layout the target imageView
        targetImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            targetImageView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 50),
            targetImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetImageView.widthAnchor.constraint(equalToConstant: 250),
            targetImageView.heightAnchor.constraint(equalToConstant: 250)
        ])
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.layer.cornerRadius = 10
        applyButton.backgroundColor = .white
        applyButton.setTitleColor(.black, for: .normal)
        let applyTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapApply))
        applyButton.addGestureRecognizer(applyTapGesture)
        applyButton.setTitle("Apply Card", for: .normal)
        NSLayoutConstraint.activate([
            applyButton.topAnchor.constraint(equalTo: targetImageView.bottomAnchor, constant: 50),
            applyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            applyButton.widthAnchor.constraint(equalToConstant: 100),
            applyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    @objc func didTapApply() {
        print("tap apply button")
        if applyButton.title(for: .normal) == "Apply Card" {
            guard let targetImage = targetImage else {
                print("No image selected from photo library.")
                return
            }            
            // 確保 UIImage 能成功轉換為 CIImage
            guard CIImage(image: targetImage) != nil else {
                print("Failed to convert UIImage to CIImage.")
                return
            }
            //        // 計算直方圖
            let targetHistogramData = histogram.calculateHistogram(for: targetImage)
            let filterHistogramData = histogram.calculateHistogram(for: filterImage)
            //        // 確認是否成功計算
            if let redHistogram = targetHistogramData["red"], !redHistogram.allSatisfy({ $0 == 0 }) {
                print("Red channel histogram calculated successfully.")
            } else {
                print("Failed to calculate valid histogram data.")
                return
            }
            let targetValues = [calculateBrightness(from: targetHistogramData),
                                calculateContrastFromHistogram(histogramData: targetHistogramData),
                                calculateSaturation(from: targetHistogramData)]
            let filterValues = [calculateBrightness(from: filterHistogramData),
                                calculateContrastFromHistogram(histogramData: filterHistogramData),
                                calculateSaturation(from: filterHistogramData)]
            let tValues = [tBrightness, tContrast, tSaturation]
            print("targetValues: \(targetValues)")
            print("filterValues: \(filterValues)")
            let smoothTargetValues = applySmoothFilterWithDifferentT(targetValues: targetValues, filterValues: filterValues, tValues: tValues)
            print(smoothTargetValues)
            let targetCIVector = calculateColor(from: targetHistogramData)
            print("targetColor\(targetCIVector)")
            let filterCIVector = calculateColor(from: filterHistogramData)
            print("filterColor\(filterCIVector)")
            colorVector = calculateColorAdjustments(targetValues: targetCIVector, filterValues: filterCIVector)
            targetImageView.image = applyImageAdjustments(image: targetImage, smoothValues: scaledValues ?? [0, 0, 0], colorVector: colorVector)
            applyButton.setTitle("Save Image", for: .normal)
        } else if applyButton.title(for: .normal) == "Save Image" {
            // 保存圖片邏輯
            saveFilteredImageToLibrary()
            addPhotoData()
            applyButton.setTitle("Apply Card", for: .normal)
        }

    }
    func calculateColorAdjustments(targetValues: [Float], filterValues: [Float]) -> [Float] {

        for targetValue in 0..<targetValues.count {
            let newValue = (targetValues[targetValue] - filterValues[targetValue]) / 255
            colorVector.append(newValue)
        }
        print(colorVector)
        return colorVector
    }
    func addPhotoData() {
        guard let image = targetImageView.image else {
            print("cant find target image")
            return
        }
        let cardID = card?.id
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
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                print("保存失敗: \(error.localizedDescription)")
            } else {
                print("照片已保存到相簿")
            }
        }
    
    func applySmoothFilterWithDifferentT(targetValues: [Float], filterValues: [Float], tValues: [Float]) {
        var result = [Float]()
        for targetValue in 0..<targetValues.count {
            let newValue = /*targetValues[targetValue] + */(filterValues[targetValue] - targetValues[targetValue]) * tValues[targetValue]
            result.append(newValue)
        }
        scaleFactor(newValue: result, brightnessScale: 1, contrastScale: 1, saturationScale: 1)
    }
    
    func scaleFactor(newValue: [Float], brightnessScale: Float, contrastScale: Float, saturationScale: Float) {

        let scaledBrightness = newValue[0] * brightnessScale
        let scaledContrast = (newValue[1] + 1) * contrastScale
        let scaledSaturation = (newValue[2] + 1) * saturationScale
        scaledValues = [scaledBrightness, scaledContrast, scaledSaturation]
        print("scaled value\(scaledValues)")
    }
    
    func applyImageAdjustments(image: UIImage, smoothValues: [Float], colorVector: [Float]) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        // 確保 colorVector 是在 0 到 1 之間的浮點數
        let rAdjustment = max(0, min(0.1, colorVector[0]))   // 正規化顏色值
        let gAdjustment = max(0, min(0.1, colorVector[1]))
        let bAdjustment = max(0, min(0.1, colorVector[2]))
        print("after adjustment \(rAdjustment), \(gAdjustment), \(bAdjustment)")
        let rVector = CIVector(x: CGFloat(rAdjustment), y: 0.0, z: 0.0, w: 0.0)
        let gVector = CIVector(x: 0.0, y: CGFloat(gAdjustment), z: 0.0, w: 0.0)
        let bVector = CIVector(x: 0.0, y: 0.0, z: CGFloat(bAdjustment), w: 0.0)
        let aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0) // 透明度保持不變
        // 使用 CIColorControls 濾鏡調整亮度、對比度、飽和度
        let colorControlsFilter = CIFilter(name: "CIColorControls")
        colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        colorControlsFilter?.setValue(smoothValues[0], forKey: kCIInputBrightnessKey)
        colorControlsFilter?.setValue(smoothValues[1], forKey: kCIInputContrastKey)
        colorControlsFilter?.setValue(smoothValues[2], forKey: kCIInputSaturationKey)
        guard let colorControlsOutput = colorControlsFilter?.outputImage else { return nil }
        // 使用 CIColorMatrix 濾鏡應用顏色調整
        let colorMatrixFilter = CIFilter(name: "CIColorMatrix")
        colorMatrixFilter?.setDefaults()
        colorMatrixFilter?.setValue(colorControlsOutput, forKey: kCIInputImageKey)
        colorMatrixFilter?.setValue(rVector, forKey: "inputRVector")
        colorMatrixFilter?.setValue(gVector, forKey: "inputGVector")
        colorMatrixFilter?.setValue(bVector, forKey: "inputBVector")
        colorMatrixFilter?.setValue(aVector, forKey: "inputAVector")
        guard let colorMatrixOutput = colorMatrixFilter?.outputImage else { return nil }
        // 將處理過的圖片轉換為 UIImage
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(colorMatrixOutput, from: colorMatrixOutput.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    @objc func targetImageTapped() {
        let alert = UIAlertController(title: "Select Image", message: "Choose from photo library or camera", preferredStyle: .actionSheet)
        // Photo library option
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentPhotoLibrary()
        }
        // Camera option
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            let cameraVC = CameraViewController()
            cameraVC.delegate = self
            self.present(cameraVC, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)        
        alert.addAction(photoLibraryAction)
        alert.addAction(cameraAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func presentPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    // Handle selected image from the photo library
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           if let selectedImage = info[.originalImage] as? UIImage {
               targetImage = selectedImage // 保存選取的圖片
               targetImageView.image = selectedImage
               targetImageView.contentMode = .scaleAspectFit
           }
           dismiss(animated: true, completion: nil)
       }
    
    func didCapturePhoto(_ image: UIImage) {
            // 接收到照片後處理
            targetImage = image
            targetImageView.image = image
            applyButton.setTitle("Apply Card", for: .normal) // Reset button after capturing photo
        }
}
