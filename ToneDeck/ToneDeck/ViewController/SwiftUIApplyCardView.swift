//
//  SwiftUIApplyCardView.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/29.
//

import SwiftUI

import SwiftUI
import PhotosUI
import CoreImage
import Firebase
import Kingfisher

struct ApplyCardView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var targetImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    @State private var showCameraView = false
    @State private var showImageAdjustment = false
    @State private var isApplied = false
    @State private var isShowPhotoPicker = false
    @State private var showingImageSourceAlert = false
    let card: Card
    let fireStoreService = FirestoreService()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")

    var body: some View {
        VStack {
            // Card Image
            KFImage(URL(string: card.imageURL))
                .resizable()
                .scaledToFit()
                .frame(height: 200)

            Text(card.cardName)
                .font(.headline)

            // Target Image
            ZStack {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .frame(width: 250, height: 250)

                if let image = targetImage {
                    Button(action: {
                        showingImageSourceAlert = true
                    }, label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                    })
                } else {
                    Button(action: {
                        showingImageSourceAlert = true
                    }) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()

            if targetImage != nil {
                Button(action: {
                    if !isApplied {
                         targetImage = applyFilter(for: targetImage ?? UIImage())


                    } else {
                        showImageAdjustment = true
                    }
                }) { Text(isApplied ? "Customize" : "Apply Card")
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
            }
        }
        .alert("Choose Image Source", isPresented: $showingImageSourceAlert) {
            Button("Photo Library") {
                isShowPhotoPicker = true
            }
            Button("Camera") {
                showCameraView = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isShowPhotoPicker) {
            PhotosPicker(selection: $imageSelection, matching: .images) {
                Text("choose from library")
            }
            .onChange(of: imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        targetImage = uiImage
                        isShowPhotoPicker = false
                    }
                }
            }
        }
        .sheet(isPresented: $showCameraView) {
            NoFilterCameraView{ capturedImage in
                targetImage = capturedImage
                showCameraView = false
            }
        }
        .sheet(isPresented: $showImageAdjustment) {
            if let image = targetImage {
                ImageAdjustmentView(card: card, originalImage: image) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func applyFilter(for targetImage: UIImage) -> UIImage {
        var hueColor: Float = 0
        // 確保 UIImage 能成功轉換為 CIImage
        guard let ciImage = CIImage(image: targetImage) else {
            print("====== Failed to convert UIImage to CIImage.")
            return targetImage
        }
        let histogram = ImageHistogramCalculator()
        let targetHistogramData = histogram.calculateHistogram(for: targetImage)
        let targetValues = [calculateBrightness(from: targetHistogramData),
                            calculateContrastFromHistogram(histogramData: targetHistogramData),
                            calculateSaturation(from: targetHistogramData)]
        let filterValues = [card.filterData[0],card.filterData[1], card.filterData[2] ]
        let tValues = [1, 1.1, 1] as? [Float]
        print("targetValues: \(targetValues)")
        print("filterValues: \(filterValues)")
        guard let tValues = tValues else {return UIImage()}
        let smoothTargetValues = applySmoothFilterWithDifferentT(targetValues: targetValues, filterValues: filterValues, tValues: tValues)
        let targetColorValue = getDominantColor(from: targetImage)

        let filterColorValue = card.filterData[3]
        if targetColorValue != 0 {
             hueColor = fabsf(filterColorValue - targetColorValue)
            print("hueColor: \(hueColor)")
        } else {
            print("One or both color values are missing or targetColorValue is 0. Skipping calculation.")
        }
        isApplied = true
        return applyImageAdjustments(image: targetImage, smoothValues: smoothTargetValues, hueAdjustment: hueColor) ?? UIImage()

//        guard let cgImage = targetImage.cgImage else {
//                print("Failed to get CGImage from UIImage.")
//                return targetImage
//            }
//
//        let ciImage = CIImage(cgImage: cgImage)
//        guard CIImage(image: targetImage) != nil else {
//            print("Failed to convert UIImage to CIImage.")
//            return targetImage
//        }
//            let histogram = ImageHistogramCalculator()
//            let targetHistogramData = histogram.calculateHistogram(for: targetImage)
//        print("Target Histogram Data: \(targetHistogramData)")
//            let targetValues = [calculateBrightness(from: targetHistogramData),
//                                calculateContrastFromHistogram(histogramData: targetHistogramData),
//                                calculateSaturation(from: targetHistogramData)]
//        print("targetValues: \(targetValues)")
//
//            // Convert the slice to a full array
//            let filterValues = Array(card.filterData[0...2])
//        print("filterValues: \(filterValues)")
//            let tValues: [Float] = [1, 1.1, 1]
//
//            let smoothTargetValues = applySmoothFilterWithDifferentT(targetValues: targetValues, filterValues: filterValues, tValues: tValues)
//            let targetColorValue = getDominantColor(from: targetImage)
//        print("targetColorValue: \(targetColorValue)")
//            let hueColor = abs(card.filterData[3] - targetColorValue)
//
//            if let processedImage = applyImageAdjustments(image: targetImage, smoothValues: smoothTargetValues, hueAdjustment: hueColor) {
//                isApplied = true
//                if fromUserID != card.creatorID {
//                    sendNotification(card: card)
//                }
//                return processedImage
//
//            } else {
//                print("Failed to apply image adjustments")
//                return targetImage
//            }
        }
    private func applySmoothFilterWithDifferentT(targetValues: [Float], filterValues: [Float], tValues: [Float]) -> [Float] {
        var result = [Float]()
        for targetValue in 0..<targetValues.count {
            let newValue = (filterValues[targetValue] - targetValues[targetValue]) * tValues[targetValue]
            result.append(newValue)
        }
        return result
    }
    private func applyImageAdjustments(image: UIImage, smoothValues: [Float], hueAdjustment: Float) -> UIImage? {
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
    private func sendNotification(card: Card) {
        let notifications = Firestore.firestore() .collection("notifications")
        guard let user = fireStoreService.user else { return }
        let document = notifications.document()

        let data: [String: Any] = [
            "id": document.documentID,
            "fromUserPhoto": user.avatar,
            "from": fromUserID ?? "",
            "to": card.id,
            "postImage": card.imageURL,
            "type": NotificationType.useCard.rawValue,
            "createdTime": Timestamp()
        ]
        document.setData(data)
    }
}
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

// Note: You'll need to implement NoFilterCameraView and ImageAdjustmentView as SwiftUI views
