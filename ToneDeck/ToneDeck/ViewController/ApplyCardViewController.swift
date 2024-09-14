//
//  ApplyCardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/13.
//

import SwiftUI
import UIKit
import PhotosUI

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
class ApplyCardViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var card: Card?
    let imageView = UIImageView()
    let targetImageView = UIImageView()
    let applyButton = UIButton()
    let cameraButton = UIButton(type: .system)
    let histogram = ImageHistogramCalculator()
    var targetImage: UIImage? // 用來保存選取的圖片
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Configure the card imageView and label
        if let card = card {
            imageView.kf.setImage(with: URL(string: card.imageURL))
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
        targetImageView.contentMode = .center
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
        let applyTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapApply))
        applyButton.addGestureRecognizer(applyTapGesture)
        applyButton.titleLabel?.text = "Apply Card"
        
        NSLayoutConstraint.activate([
            applyButton.topAnchor.constraint(equalTo: targetImageView.bottomAnchor, constant: 50),
            applyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            applyButton.widthAnchor.constraint(equalToConstant: 100),
            applyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func didTapApply() {
        print("tap apply button")
        
        guard let targetImage = targetImage else {
                    print("No image selected from photo library.")
                    return
                }
        
        // 確保 UIImage 能成功轉換為 CIImage
        guard let ciImage = CIImage(image: targetImage) else {
            print("Failed to convert UIImage to CIImage.")
            return
        }
        
//        // 計算直方圖
        histogram.calculateHistogram(for: targetImage)
//
//        // 確認是否成功計算
        if let redHistogram = histogramData["red"], !redHistogram.allSatisfy({ $0 == 0 }) {
            print("Red channel histogram calculated successfully.")
        } else {
            print("Failed to calculate valid histogram data.")
            return
        }
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
               targetImageView.contentMode = .scaleAspectFill
           }
           dismiss(animated: true, completion: nil)
       }
}


