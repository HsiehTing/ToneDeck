//
//  SecondApplyCardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/24.
//

import SwiftUI
import UIKit
import PhotosUI
import CoreImage
import FirebaseStorage
import Firebase

struct SecondApplyCardViewControllerWrapper: UIViewControllerRepresentable {
    let card: Card?
    func makeUIViewController(context: Context) -> SecondApplyCardViewController {
        let viewController = SecondApplyCardViewController()
        viewController.card = card
        return viewController
    }
    func updateUIViewController(_ uiViewController: SecondApplyCardViewController, context: Context) {}
}

// UIKit ViewController (ApplyCardViewController)
class SecondApplyCardViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraViewControllerDelegate {
    var card: Card?
    let imageView = UIImageView()
    let targetImageView = UIImageView()
    var filterImage = UIImage()
    let nameLabel = UILabel()
    let applyButton = UIButton()

    let cameraButton = UIButton(type: .system)
    let histogram = ImageHistogramCalculator()
    var targetImage: UIImage? // 用來保存選取的圖片
    var tBrightness: Float = 1  // 較平滑的亮度變化
    var tContrast: Float = 1.1    // 中等強度的對比度變化
    var tSaturation: Float = 1  // 更強的飽和度變化
    var scaledValues: [Float]?
    var filterColorValue: Float?
    var colorVector: [Float] = []
    var hueColor: Float?
    let fireStoreService = FirestoreService()
    let meshGradientView = UIKitMeshGradient(frame: CGRect(x: 0, y: 0, width: 250, height: 320))
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    override func viewDidLoad() {
           super.viewDidLoad()
           view.backgroundColor = .black
           // Configure the card imageView and label
           fireStoreService.fetchUserData(userID: fromUserID ?? "")
           if let card = card {
               imageView.kf.setImage(with: URL(string: card.imageURL))
               filterImage = imageView.image ?? UIImage()
               nameLabel.text = card.cardName
           }
           //targetImageView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        nameLabel.textColor = .white
        nameLabel.font = UIFont(name: "PlayfairDisplayItalic-Black", size: 52)
        view.addSubview(imageView)
        view.addSubview(nameLabel)
        view.addSubview(applyButton)
        // Layout card imageView and label
        imageView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: -25),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            imageView.widthAnchor.constraint(equalToConstant: 400)
        ])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        targetImageView.tintColor = .white
        targetImageView.isUserInteractionEnabled = true
        view.addSubview(targetImageView)

           // 添加虛線邊框
           //targetImageView.layer.borderColor = UIColor.white.cgColor
           targetImageView.layer.borderWidth = 2
           targetImageView.layer.cornerRadius = 20
           targetImageView.layer.masksToBounds = true
           let dashBorder = CAShapeLayer()
           dashBorder.strokeColor = UIColor.white.cgColor
           dashBorder.lineDashPattern = [16, 8] // 虛線的樣式：6點劃線，3點空白
           dashBorder.frame = targetImageView.bounds
           dashBorder.fillColor = nil
           dashBorder.path = UIBezierPath(roundedRect: targetImageView.bounds, cornerRadius: 10).cgPath
           targetImageView.layer.addSublayer(dashBorder)
           targetImageView.contentMode = .scaleAspectFill
           targetImageView.clipsToBounds = true
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(targetImageTapped))
           targetImageView.addGestureRecognizer(tapGesture)

           // Layout the target imageView
           targetImageView.translatesAutoresizingMaskIntoConstraints = false
           NSLayoutConstraint.activate([
               targetImageView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
               targetImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               targetImageView.widthAnchor.constraint(equalToConstant: 400),
               targetImageView.heightAnchor.constraint(equalToConstant: 300)
           ])
        guard let dominantColor = card?.dominantColor else {return}
        meshGradientView.setTargetColorRGBA(red: dominantColor.red , green: dominantColor.green , blue: dominantColor.blue , alpha: 1)
        targetImageView.addSubview(meshGradientView)
        let iconImageView = UIImageView()
        let importLabel = UILabel()
        iconImageView.image = UIImage(systemName: "square.and.arrow.down.fill")
        meshGradientView.addSubview(iconImageView)
        meshGradientView.addSubview(importLabel)
        importLabel.text = "Import photo"
        importLabel.font = UIFont(name: "PlayfairDisplay-Regular", size: 32)
        importLabel.textAlignment = .center
        meshGradientView.translatesAutoresizingMaskIntoConstraints = false
        importLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            meshGradientView.centerXAnchor.constraint(equalTo: targetImageView.centerXAnchor),
            meshGradientView.centerYAnchor.constraint(equalTo: targetImageView.centerYAnchor),
            meshGradientView.widthAnchor.constraint(equalToConstant: 400),
            meshGradientView.heightAnchor.constraint(equalToConstant: 300),

            iconImageView.centerXAnchor.constraint(equalTo: targetImageView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: meshGradientView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 120),  // Set a width for the icon
            iconImageView.heightAnchor.constraint(equalToConstant: 120),  // Set a height for the icon
            importLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            importLabel.centerXAnchor.constraint(equalTo: targetImageView.centerXAnchor),
            importLabel.widthAnchor.constraint(equalToConstant: 200),
            importLabel.heightAnchor.constraint(equalToConstant: 36),
        ])
        iconImageView.alpha = 0.3
           applyButton.translatesAutoresizingMaskIntoConstraints = false
           applyButton.layer.cornerRadius = 15
           applyButton.backgroundColor = .white

           let applyTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapApply))
           applyButton.addGestureRecognizer(applyTapGesture)
        applyButton.setTitleColor(.darkGray, for: .normal)
        applyButton.setTitle("Apply Card", for: .normal)
           NSLayoutConstraint.activate([
               applyButton.topAnchor.constraint(equalTo: targetImageView.bottomAnchor, constant: 20),
               applyButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
               applyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               applyButton.widthAnchor.constraint(equalToConstant: 100),
               applyButton.heightAnchor.constraint(equalToConstant: 40)
           ])
           guard let card = card else {print("did not find card"); return}
           filterColorValue = card.filterData[3]
       }
    @objc func didTapApply() {
        print("tap apply button")
        guard let targetImage = targetImage else {
            print("No image selected from photo library.")
            return
        }
        // 確保 UIImage 能成功轉換為 CIImage
        guard CIImage(image: targetImage) != nil else {
            print("Failed to convert UIImage to CIImage.")
            return
        }
        // 計算直方圖
        let targetHistogramData = histogram.calculateHistogram(for: targetImage)
        let filterHistogramData = histogram.calculateHistogram(for: filterImage)
        // 確認是否成功計算
        let targetValues = [calculateBrightness(from: targetHistogramData),
                            calculateContrastFromHistogram(histogramData: targetHistogramData),
                            calculateSaturation(from: targetHistogramData)]
        guard let card = card else { return }
        let filterValues = [card.filterData[0], card.filterData[1], card.filterData[2]]
        let tValues = [tBrightness, tContrast, tSaturation]
        print("targetValues: \(targetValues)")
        print("filterValues: \(filterValues)")
        let smoothTargetValues = applySmoothFilterWithDifferentT(targetValues: targetValues, filterValues: filterValues, tValues: tValues)
        print(smoothTargetValues)
        let targetColorValue = getDominantColor(from: targetImage)
        if let filterColorValue = filterColorValue, targetColorValue != 0 {
            self.hueColor = fabsf(filterColorValue - targetColorValue)
            print("hueColor: \(hueColor)")
        } else {
            print("One or both color values are missing or targetColorValue is 0. Skipping calculation.")
        }
        print("targetColor\(targetColorValue)")
        print("filterColor\(filterColorValue)")
        let outputImage = applyImageAdjustments(image: targetImage, smoothValues: scaledValues ?? [0, 0, 0], hueAdjustment: hueColor ?? 10)!

        self.meshGradientView.isHidden = true

        if fromUserID != card.creatorID {
            sendNotification(card: card)
        }

        // Directly present the ImageAdjustmentView
        let imageAdjustmentView = ImageAdjustmentView(card: card, originalImage: outputImage) { [weak self] in
            // This completion block will be called when the ImageAdjustmentView is dismissed
            self?.dismiss(animated: true, completion: {
                // After dismissing ImageAdjustmentView, navigate back to the CardView
                self?.navigationController?.popViewController(animated: true)
            })
        }
        let hostingController = UIHostingController(rootView: imageAdjustmentView)

        // Present the UIHostingController modally
        self.present(hostingController, animated: true, completion: nil)
    }
    func applySmoothFilterWithDifferentT(targetValues: [Float], filterValues: [Float], tValues: [Float]) {
        var result = [Float]()
        for targetValue in 0..<targetValues.count {
            let newValue = /*targetValues[targetValue] + */(filterValues[targetValue] - targetValues[targetValue]) * tValues[targetValue]
            result.append(newValue)
        }
        scaleFactor(newValue: result, brightnessScale: 1, contrastScale: 1.1, saturationScale: 1)
    }
    func scaleFactor(newValue: [Float], brightnessScale: Float, contrastScale: Float, saturationScale: Float) {
        let scaledBrightness = newValue[0] * brightnessScale
        let scaledContrast = (newValue[1] + 1) * contrastScale
        let scaledSaturation = (newValue[2] + 1) * saturationScale
        scaledValues = [scaledBrightness, scaledContrast, scaledSaturation]
        print("scaled value\(scaledValues)")
    }
    func applyImageAdjustments(image: UIImage, smoothValues: [Float], hueAdjustment: Float) -> UIImage? {
        let orientation = image.imageOrientation
        guard let ciImage = CIImage(image: image) else { return nil }
        let colorControlsFilter = CIFilter(name: "CIColorControls")
        colorControlsFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        colorControlsFilter?.setValue(smoothValues[0], forKey: kCIInputBrightnessKey)
        colorControlsFilter?.setValue(smoothValues[1], forKey: kCIInputContrastKey)
        colorControlsFilter?.setValue(smoothValues[2], forKey: kCIInputSaturationKey)
        guard let colorControlsOutput = colorControlsFilter?.outputImage else { return nil }
        let hueAdjustFilter = CIFilter(name: "CIHueAdjust")
        hueAdjustFilter?.setDefaults()
        hueAdjustFilter?.setValue(colorControlsOutput, forKey: kCIInputImageKey)
        hueAdjustFilter?.setValue(hueAdjustment, forKey: kCIInputAngleKey)
        guard let hueAdjustOutput = hueAdjustFilter?.outputImage else { return nil }
        let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(hueAdjustOutput, from: hueAdjustOutput.extent) else { return nil }
        let returnImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        return returnImage
    }
    @objc func targetImageTapped() {
        let alert = UIAlertController(title: "Select Image", message: "Choose from photo library or camera", preferredStyle: .actionSheet)
        // Photo library option
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentPhotoLibrary()
        }
        // Camera option
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            var cameraVC = NoFilterCameraView(){_ in 

            }
            cameraVC.delegate = self
                let hostingController = UIHostingController(rootView: cameraVC)
            self.navigationController?.pushViewController(hostingController, animated: true)
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
               self.meshGradientView.isHidden = true
               targetImageView.image = selectedImage
           }
           dismiss(animated: true, completion: nil)
       }
    func didCapturePhoto(_ image: UIImage) {
            // 接收到照片後處理
            targetImage = image
            targetImageView.image = image
            applyButton.setTitle("Apply Card", for: .normal) // Reset button after capturing photo
        }
    func sendNotification(card: Card) {
        let notifications = Firestore.firestore().collection("notifications")
        let user = fireStoreService.user
        let document = notifications.document()
        guard let user = user else {return}
        let data: [String: Any] = [
             "id": document.documentID,
             "fromUserPhoto": user.avatar,
             "from": fromUserID,
             "to": card.creatorID,
             "postImage": card.imageURL,
             "type": NotificationType.useCard.rawValue,
             "createdTime": Timestamp()
        ]
        document.setData(data)
    }
}
