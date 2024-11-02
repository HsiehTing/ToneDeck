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
import Combine

struct ApplyCardViewControllerWrapper: UIViewControllerRepresentable {
    let card: Card?

    func makeUIViewController(context: Context) -> ApplyCardViewController {
        let viewController = ApplyCardViewController()
        viewController.card = card
        return viewController
    }

    func updateUIViewController(_ uiViewController: ApplyCardViewController, context: Context) {}
}
struct ApplyCardView: View {
    @StateObject private var viewModel: ApplyCardViewModel
    @Environment(\.presentationMode) var presentationMode

    init(card: Card) {
        _viewModel = StateObject(wrappedValue: ApplyCardViewModel(card: card))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 12) {
                // Back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }

                // Main content
                CardPreviewView(viewModel: viewModel)

                // Apply button
                ApplyButton(viewModel: viewModel)
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}
class ApplyCardViewModel: ObservableObject {
    @Published var targetImage: UIImage?
    @Published var isGradientHidden = false
    @Published var scaledValues: [Float]?
    @Published var hueColor: Float?

    let card: Card
    private let histogram = ImageHistogramCalculator()
    private let fireStoreService = FirestoreService()
    private let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")

    init(card: Card) {
        self.card = card
    }

    // MARK: - Public Methods
    func processApplyFilter() -> UIImage? {
        guard let targetImage = targetImage else {
            print("No image selected from photo library.")
            return nil
        }

        let targetHistogramData = histogram.calculateHistogram(for: targetImage)
        //let filterHistogramData = histogram.calculateHistogram(for: card.imageURL)

        let targetValues = [
            calculateBrightness(from: targetHistogramData),
            calculateContrastFromHistogram(histogramData: targetHistogramData),
            calculateSaturation(from: targetHistogramData)
        ]

        let filterValues = [card.filterData[0], card.filterData[1], card.filterData[2]]
        let tValues:[Float] = [1.00, 1.30, 1.00] // Default values for brightness, contrast, saturation

        applySmoothFilterWithDifferentT(targetValues: targetValues, filterValues: filterValues, tValues: tValues)

        let targetColorValue = getDominantColor(from: targetImage)
        let filterColorValue = card.filterData[3]
        if  targetColorValue != 0 {
            self.hueColor = filterColorValue - targetColorValue
        }

        return applyImageAdjustments(image: targetImage,
                                   smoothValues: scaledValues ?? [0, 0, 0],
                                   hueAdjustment: hueColor ?? 10)
    }

    func sendNotification() {
        guard fromUserID != card.creatorID else { return }

        let notifications = Firestore.firestore().collection("notifications")
        let document = notifications.document()

        guard let user = fireStoreService.user else { return }

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

    // MARK: - Private Methods
    private func applySmoothFilterWithDifferentT(targetValues: [Float], filterValues: [Float], tValues: [Float]) {
        var result = [Float]()
        for targetValue in 0..<targetValues.count {
            let newValue = (filterValues[targetValue] - targetValues[targetValue]) * tValues[targetValue]
            result.append(newValue)
        }
        scaleFactor(newValue: result, brightnessScale: 1.0, contrastScale: 1.2, saturationScale: 1)
    }

    private func scaleFactor(newValue: [Float], brightnessScale: Float, contrastScale: Float, saturationScale: Float) {
        let scaledBrightness = newValue[0] * brightnessScale
        let scaledContrast = (newValue[1] + 1) * contrastScale
        let scaledSaturation = (newValue[2] + 1) * saturationScale
        scaledValues = [scaledBrightness, scaledContrast, scaledSaturation]
    }

    private func applyImageAdjustments(image: UIImage, smoothValues: [Float], hueAdjustment: Float) -> UIImage? {
        let orientation = image.imageOrientation
        guard let ciImage = CIImage(image: image) else { return nil }

        // Apply color controls
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

        let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(hueAdjustOutput, from: hueAdjustOutput.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}
class ApplyCardViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraViewControllerDelegate {
    private let viewModel: ApplyCardViewModel

    private let imageView = UIImageView()
    private let targetImageView = UIImageView()
    private let nameLabel = UILabel()
    private let applyButton = UIButton()
    private var meshGradientView: UIKitMeshGradient!

    init(viewModel: ApplyCardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupBindings()
    }

    private func configureUI() {
        view.backgroundColor = .black
        configureImageViews()
        configureNameLabel()
        configureApplyButton()
        configureMeshGradient()
        setupConstraints()
    }

    private func configureImageViews() {
        // Configure filter image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.kf.setImage(with: URL(string: viewModel.card.imageURL))
        view.addSubview(imageView)

        // Configure target image view
        targetImageView.contentMode = .scaleAspectFill
        targetImageView.clipsToBounds = true
        targetImageView.layer.cornerRadius = 20
        targetImageView.layer.borderWidth = 2
        targetImageView.isUserInteractionEnabled = true
        view.addSubview(targetImageView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(targetImageTapped))
        targetImageView.addGestureRecognizer(tapGesture)
    }

    private func configureNameLabel() {
        nameLabel.textColor = .white
        nameLabel.font = UIFont(name: "PlayfairDisplayItalic-Black", size: 42)
        nameLabel.text = viewModel.card.cardName
        view.addSubview(nameLabel)
    }

    private func configureApplyButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)
        let image = UIImage(systemName: "apple.image.playground.fill", withConfiguration: config)
        applyButton.setImage(image, for: .normal)
        applyButton.tintColor = UIColor(
            red: viewModel.card.dominantColor.red,
            green: viewModel.card.dominantColor.green,
            blue: viewModel.card.dominantColor.blue,
            alpha: 1
        )
        applyButton.backgroundColor = UIColor(
            red: viewModel.card.dominantColor.red,
            green: viewModel.card.dominantColor.green,
            blue: viewModel.card.dominantColor.blue,
            alpha: 0.6
        )
        applyButton.alpha = 0.7
        applyButton.layer.cornerRadius = 10
        applyButton.addTarget(self, action: #selector(didTapApply), for: .touchUpInside)
        view.addSubview(applyButton)
    }

    private func configureMeshGradient() {
        meshGradientView = UIKitMeshGradient(frame: .zero)
        meshGradientView.setTargetColorRGBA(
            red: viewModel.card.dominantColor.red,
            green: viewModel.card.dominantColor.green,
            blue: viewModel.card.dominantColor.blue,
            alpha: 1
        )
        targetImageView.addSubview(meshGradientView)
    }

    private func setupConstraints() {
        let views = [imageView, nameLabel, targetImageView, applyButton, meshGradientView]
        views.forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        let screenWidth = UIScreen.main.bounds.width

        NSLayoutConstraint.activate([
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.1 * screenWidth),
            nameLabel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Filter Image View
            imageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: -0.07 * screenWidth),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.8),

            // Target Image View
            targetImageView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            targetImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            targetImageView.heightAnchor.constraint(equalTo: targetImageView.widthAnchor, multiplier: 0.8),

            // Mesh Gradient View
            meshGradientView.topAnchor.constraint(equalTo: targetImageView.topAnchor),
            meshGradientView.leadingAnchor.constraint(equalTo: targetImageView.leadingAnchor),
            meshGradientView.trailingAnchor.constraint(equalTo: targetImageView.trailingAnchor),
            meshGradientView.bottomAnchor.constraint(equalTo: targetImageView.bottomAnchor),

            // Apply Button
            applyButton.topAnchor.constraint(equalTo: targetImageView.bottomAnchor, constant: 0.05 * screenWidth),
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            applyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            applyButton.widthAnchor.constraint(equalToConstant: 80),
            applyButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupBindings() {
        // Observe ViewModel's published properties
        var cancellables = Set<AnyCancellable>()
        viewModel.$targetImage.sink { [weak self] image in
            self?.targetImageView.image = image
        }.store(in: &cancellables)

        viewModel.$isGradientHidden.sink { [weak self] isHidden in
            self?.meshGradientView.isHidden = isHidden
        }.store(in: &cancellables)
    }

    @objc private func targetImageTapped() {
        let alert = UIAlertController(title: "Select Image", message: "Choose from photo library or camera", preferredStyle: .actionSheet)

        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        }

        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            var cameraVC = NoFilterCameraView() { _ in }
            cameraVC.delegate = self
            let hostingController = UIHostingController(rootView: cameraVC)
            self?.navigationController?.pushViewController(hostingController, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        [photoLibraryAction, cameraAction, cancelAction].forEach { alert.addAction($0) }

        present(alert, animated: true)
    }

    @objc private func didTapApply() {
        guard let outputImage = viewModel.processApplyFilter() else { return }
        viewModel.sendNotification()

        let imageAdjustmentView = ImageAdjustmentView(card: viewModel.card, originalImage: outputImage) { [weak self] in
            self?.dismiss(animated: true) {
                self?.navigationController?.popViewController(animated: true)
            }
        }

        let hostingController = UIHostingController(rootView: imageAdjustmentView)
        present(hostingController, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            viewModel.updateTargetImage(selectedImage)
        }
        dismiss(animated: true)
    }

    // MARK: - CameraViewControllerDelegate
    func didCapturePhoto(_ image: UIImage) {
        viewModel.updateTargetImage(image)
    }

    func presentPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
}

//============================================================================================
class ApplyCardViewControllerUnfactor: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraViewControllerDelegate {
    var card: Card?
    let imageView = UIImageView()
    let targetImageView = UIImageView()
    var filterImage = UIImage()
    let nameLabel = UILabel()
    let applyButton = UIButton()

    let cameraButton = UIButton(type: .system)
    let histogram = ImageHistogramCalculator()
    var targetImage: UIImage?
    var tBrightness: Float = 1
    var tContrast: Float = 1.3
    var tSaturation: Float = 1
    var scaledValues: [Float]?
    var filterColorValue: Float?
    var colorVector: [Float] = []
    var hueColor: Float?
    let fireStoreService = FirestoreService()
    var meshGradientView = UIKitMeshGradient(frame: CGRect(x: 0, y: 0, width: 250, height: 320))
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    override func viewDidLoad() {
           super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
           view.backgroundColor = .black
        configUI()

           fireStoreService.fetchUserData(userID: fromUserID ?? "")
           if let card = card {
               imageView.kf.setImage(with: URL(string: card.imageURL))
               filterImage = imageView.image ?? UIImage()
               nameLabel.text = card.cardName
           }

           let applyTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapApply))
           applyButton.addGestureRecognizer(applyTapGesture)

           guard let card = card else {print("did not find card"); return}
           filterColorValue = card.filterData[3]
       }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
           navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           navigationController?.setNavigationBarHidden(false, animated: animated)
       }
    func configUI() {
        let screenWidth = UIScreen.main.bounds.width
        nameLabel.textColor = .white
               nameLabel.font = UIFont(name: "PlayfairDisplayItalic-Black", size: 42)
        view.addSubview(imageView)
        view.addSubview(nameLabel)
        view.addSubview(applyButton)
        // Layout card imageView and label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.1 * screenWidth),
            nameLabel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1 ),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: -0.07 * screenWidth),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.8),

        ])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        targetImageView.tintColor = .white
        targetImageView.isUserInteractionEnabled = true
        view.addSubview(targetImageView)



           targetImageView.layer.borderWidth = 2
           targetImageView.layer.cornerRadius = 20
           targetImageView.layer.masksToBounds = true
           let dashBorder = CAShapeLayer()
           dashBorder.strokeColor = UIColor.white.cgColor
           dashBorder.lineDashPattern = [16, 8]
           dashBorder.frame = targetImageView.bounds
           dashBorder.fillColor = nil
           dashBorder.path = UIBezierPath(roundedRect: targetImageView.bounds, cornerRadius: 10).cgPath
           targetImageView.layer.addSublayer(dashBorder)
           targetImageView.contentMode = .scaleAspectFill
           targetImageView.clipsToBounds = true
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(targetImageTapped))
           targetImageView.addGestureRecognizer(tapGesture)


           targetImageView.translatesAutoresizingMaskIntoConstraints = false
           NSLayoutConstraint.activate([
               targetImageView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
               targetImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               targetImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
               targetImageView.heightAnchor.constraint(equalTo: targetImageView.widthAnchor, multiplier: 0.8),

           ])
        guard let dominantColor = card?.dominantColor else {return}
        meshGradientView = UIKitMeshGradient(frame: CGRect(x: 0, y: 0, width: targetImageView.frame.width, height: targetImageView.frame.height))
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
            meshGradientView.widthAnchor.constraint(equalTo: targetImageView.widthAnchor),
            meshGradientView.heightAnchor.constraint(equalTo: targetImageView.heightAnchor),


            iconImageView.centerXAnchor.constraint(equalTo: targetImageView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: meshGradientView.centerYAnchor, constant: screenWidth * -0.025),
            iconImageView.widthAnchor.constraint(equalToConstant: screenWidth * 0.3),
            iconImageView.heightAnchor.constraint(equalToConstant: screenWidth * 0.3),
            importLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: screenWidth * 0.025),

            importLabel.centerXAnchor.constraint(equalTo: targetImageView.centerXAnchor),
            importLabel.widthAnchor.constraint(equalToConstant: screenWidth * 0.5),
            importLabel.heightAnchor.constraint(equalToConstant: screenWidth * 0.09)
        ])
        iconImageView.alpha = 0.3
           applyButton.translatesAutoresizingMaskIntoConstraints = false
           applyButton.layer.cornerRadius = 10
        applyButton.tintColor = UIColor(red: dominantColor.red, green: dominantColor.green, blue: dominantColor.blue, alpha: 1)
        applyButton.backgroundColor = UIColor(red: dominantColor.red, green: dominantColor.green, blue: dominantColor.blue, alpha: 0.6)
        applyButton.alpha = 0.7
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)
               let image = UIImage(systemName: "apple.image.playground.fill", withConfiguration: config)
               applyButton.setImage(image, for: .normal)
           NSLayoutConstraint.activate([
            applyButton.topAnchor.constraint(equalTo: targetImageView.bottomAnchor, constant: 0.05 * screenWidth),
               applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
               applyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               applyButton.widthAnchor.constraint(equalToConstant: 80),
               applyButton.heightAnchor.constraint(equalToConstant: 30)
           ])
    }
    @objc func didTapApply() {
        print("tap apply button")
        guard let targetImage = targetImage else {
            print("No image selected from photo library.")
            return
        }

        guard CIImage(image: targetImage) != nil else {
            print("Failed to convert UIImage to CIImage.")
            return
        }

        let targetHistogramData = histogram.calculateHistogram(for: targetImage)
        let filterHistogramData = histogram.calculateHistogram(for: filterImage)

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
            self.hueColor = filterColorValue - targetColorValue
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


        let imageAdjustmentView = ImageAdjustmentView(card: card, originalImage: outputImage) { [weak self] in

            self?.dismiss(animated: true, completion: {

                self?.navigationController?.popViewController(animated: true)
            })
        }
        let hostingController = UIHostingController(rootView: imageAdjustmentView)


        self.present(hostingController, animated: true, completion: nil)
    }
    func applySmoothFilterWithDifferentT(targetValues: [Float], filterValues: [Float], tValues: [Float]) {
        var result = [Float]()
        for targetValue in 0..<targetValues.count {
            let newValue = (filterValues[targetValue] - targetValues[targetValue]) * tValues[targetValue]
            result.append(newValue)
        }
        scaleFactor(newValue: result, brightnessScale: 1.0, contrastScale: 1.2, saturationScale: 1)
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
        guard let ciImage = CIImage(image: image)else { return nil }
        ciImage.oriented(CGImagePropertyOrientation(image.imageOrientation))
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           if let selectedImage = info[.originalImage] as? UIImage {
               targetImage = selectedImage // 保存選取的圖片
               self.meshGradientView.isHidden = true
               targetImageView.image = selectedImage


           }
           dismiss(animated: true, completion: nil)
       }
    func didCapturePhoto(_ image: UIImage) {

        print("image picked")
        self.meshGradientView.isHidden = true
            targetImage = image
        targetImageView.contentMode = .scaleAspectFill
        targetImageView.clipsToBounds = true
            targetImageView.image = image

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
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}
