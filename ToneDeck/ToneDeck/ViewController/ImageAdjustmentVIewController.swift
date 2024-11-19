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

class ImageAdjustmentViewModel: ObservableObject {
    @Environment(\.presentationMode) var presentationMode
    @Published var isAnimationTriggered: Bool? = false
    @Published var adjustedImage: UIImage?
    @Published var brightness: CGFloat = 0.0
    @Published var grain: CGFloat = 0.0
    @Published var contrast: CGFloat = 1.0
    @Published var saturation: CGFloat = 1.0
    @Published var hueAdjustment: CGFloat = 0.0
    @Published private var originalImage: UIImage
    @Published var selectedFilter: FilterType = .brightness

    init(adjustedImage: UIImage? = nil, originalImage: UIImage) {
        self.adjustedImage = adjustedImage
        self.originalImage = originalImage

    }

    enum FilterType: String, CaseIterable, Identifiable {
        case brightness = "circle.lefthalf.striped.horizontal"
        case contrast = "righttriangle"
        case saturation = "drop.halffull"
        case hue = "swirl.circle.righthalf.filled"
        case grain = "seal"
        var id: String { self.rawValue }
    }

    func applyAdjustments() {
        adjustedImage = applyImageAdjustments(
            image: originalImage,
            smoothValues: [Float(brightness), Float(contrast), Float(saturation)],
            hueAdjustment: Float(hueAdjustment), grainIntensity: Float(grain), grainSize: 2
        )
    }
}

struct ImageAdjustmentView: View {

    @StateObject private var viewModel: ImageAdjustmentViewModel
    let originalImage: UIImage
    let saveToLibrary = SaveToLibrary()
    let card: Card
    var onDismiss: (() -> Void)?
    init(originalImage: UIImage, card: Card, onDismiss: ( () -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ImageAdjustmentViewModel(originalImage: originalImage))
        self.originalImage = originalImage
        self.card = card
        self.onDismiss = onDismiss
    }
//    enum FilterType: String, CaseIterable, Identifiable {
//        case brightness = "circle.lefthalf.striped.horizontal"
//        case contrast = "righttriangle"
//        case saturation = "drop.halffull"
//        case hue = "swirl.circle.righthalf.filled"
//        case grain = "seal"
//        var id: String { self.rawValue }
//    }

    var body: some View {
        Spacer()
         VStack {
             HStack{
                 Spacer()
                 Button(action: {
                     if let image = viewModel.adjustedImage {
                         saveToLibrary.saveImageToPhotoLibrary(image: image, card: card)
                         saveToLibrary.addPhotoData(image: image, card: card)
                         onDismiss?()
                         viewModel.presentationMode.wrappedValue.dismiss()
                     }
                 }) {
                     Text("Save")
                         .padding()
                         .background(Color.white)
                         .foregroundColor(.black)
                         .buttonStyle(PlainButtonStyle())
                         .font(.caption)
                         .frame(height: 35)
                         .cornerRadius(7)
                         .padding()
                 }
                 .buttonStyle(PlainButtonStyle())
             }
             Spacer()
             if let adjustedImage = viewModel.adjustedImage {
                 Image(uiImage: adjustedImage)
                     .resizable()
                     .scaledToFit()
                     .frame(maxWidth: .infinity)
                     .bannerAnimation(isTriggered: viewModel.isAnimationTriggered ?? true)
                     .padding()

             }

             Spacer()

             switch viewModel.selectedFilter {
             case .brightness:
                 Text("Brightness")
                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
             case .contrast:
                 Text("Contrast")
                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
             case .saturation:
                 Text("Saturation")
                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
             case .hue:
                 Text("Hue")
                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
             case .grain:
                 Text("Grain")
                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
             }
             switch viewModel.selectedFilter {
             case .brightness:
                 Text("\(viewModel.brightness, specifier: "%.2f")")
                 MeshingSlider(value: $viewModel.brightness, colors: [.gray, .white], range: -1...1)
                     .onChange(of: viewModel.brightness) { _ in applyAdjustments() }
                     .frame(height: 70)
             case .contrast:
                 Text("\(viewModel.contrast, specifier: "%.2f")")
                 MeshingSlider(value: $viewModel.contrast, colors: [.gray, .white], range: 0.5...2)
                     .onChange(of: viewModel.contrast) { _ in applyAdjustments() }
                     .frame(height: 70)
             case .saturation:
                 Text("\(viewModel.saturation, specifier: "%.2f")")
                 MeshingSlider(value: $viewModel.saturation, colors: [.gray, .white], range: 0...2)
                     .onChange(of: viewModel.saturation) { _ in applyAdjustments() }
                     .frame(height: 70)
             case .hue:
                 Text("\(viewModel.hueAdjustment, specifier: "%.2f")")
                 MeshingSlider(value: $viewModel.hueAdjustment, colors: [.gray, .white], range: -CGFloat.pi...CGFloat.pi)
                     .onChange(of: viewModel.hueAdjustment) { _ in applyAdjustments() }
                     .frame(height: 70)
             case .grain:
                 Text("\(viewModel.grain, specifier: "%.2f")")
                 MeshingSlider(value: $viewModel.grain, colors: [.gray, .white], range: -1...1)
                     .onChange(of: viewModel.grain) { _ in applyAdjustments() }
                     .frame(height: 70)
             }

             Picker("Select Filter", selection: $viewModel.selectedFilter) {
                 ForEach(ImageAdjustmentViewModel.FilterType.allCases) { filter in
                     Image(systemName: filter.rawValue).tag(filter)
                 }
             }
             .pickerStyle(SegmentedPickerStyle())
             .padding()
             .buttonStyle(PlainButtonStyle())

         }
         .backgroundStyle(.black)
         .onAppear {
             applyAdjustments()
             viewModel.isAnimationTriggered = true
         }
     }

    private func applyAdjustments() {
        viewModel.adjustedImage = applyImageAdjustments(
            image: originalImage,
            smoothValues: [Float(viewModel.brightness), Float(viewModel.contrast), Float(viewModel.saturation)],
            hueAdjustment: Float(viewModel.hueAdjustment), grainIntensity: Float(viewModel.grain), grainSize: 2
        )
    }
}

//struct ImageAdjustmentView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @State private var brightness: CGFloat = 0.0
//    @State private var contrast: CGFloat = 1.0
//    @State private var saturation: CGFloat = 1.0
//    @State private var hueAdjustment: CGFloat = 0.0
//    @State private var grain: CGFloat = 0.0
//    @State var card: Card
//    @State private var isAnimationTriggered: Bool? = false
//    @State private var adjustedImage: UIImage?
//    @State private var selectedFilter: FilterType = .brightness
//    let originalImage: UIImage
//    let saveToLibrary = SaveToLibrary()
//    var onDismiss: (() -> Void)?
//
//    enum FilterType: String, CaseIterable, Identifiable {
//        case brightness = "circle.lefthalf.striped.horizontal"
//        case contrast = "righttriangle"
//        case saturation = "drop.halffull"
//        case hue = "swirl.circle.righthalf.filled"
//        case grain = "seal"
//        var id: String { self.rawValue }
//    }
//   
//    var body: some View {
//        Spacer()
//         VStack {
//             HStack{
//                 Spacer()
//                 Button(action: {
//                     if let image = adjustedImage {
//                         saveToLibrary.saveImageToPhotoLibrary(image: image, card: card)
//                         saveToLibrary.addPhotoData(image: image, card: card)
//                         onDismiss?()
//                         self.presentationMode.wrappedValue.dismiss()
//                     }
//                 }) {
//                     Text("Save")
//                         .padding()
//                         .background(Color.white)
//                         .foregroundColor(.black)
//                         .buttonStyle(PlainButtonStyle())
//                         .font(.caption)
//                         .frame(height: 35)
//                         .cornerRadius(7)
//                         .padding()
//                 }
//                 .buttonStyle(PlainButtonStyle())
//             }
//             Spacer()
//             if let adjustedImage = adjustedImage {
//                 Image(uiImage: adjustedImage)
//                     .resizable()
//                     .scaledToFit()
//                     .frame(maxWidth: .infinity)
//                     .bannerAnimation(isTriggered: isAnimationTriggered ?? true)
//                     .padding()
//
//             }
//
//             Spacer()
//
//             switch selectedFilter {
//             case .brightness:
//                 Text("Brightness")
//                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
//             case .contrast:
//                 Text("Contrast")
//                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
//             case .saturation:
//                 Text("Saturation")
//                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
//             case .hue:
//                 Text("Hue")
//                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
//             case .grain:
//                 Text("Grain")
//                     .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
//             }
//             switch selectedFilter {
//             case .brightness:
//                 Text("\(brightness, specifier: "%.2f")")
//                 MeshingSlider(value: $brightness, colors: [.gray, .white], range: -1...1)
//                     .onChange(of: brightness) { _ in applyAdjustments() }
//                     .frame(height: 70)
//             case .contrast:
//                 Text("\(contrast, specifier: "%.2f")")
//                 MeshingSlider(value: $contrast, colors: [.gray, .white], range: 0.5...2)
//                     .onChange(of: contrast) { _ in applyAdjustments() }
//                     .frame(height: 70)
//             case .saturation:
//                 Text("\(saturation, specifier: "%.2f")")
//                 MeshingSlider(value: $saturation, colors: [.gray, .white], range: 0...2)
//                     .onChange(of: saturation) { _ in applyAdjustments() }
//                     .frame(height: 70)
//             case .hue:
//                 Text("\(hueAdjustment, specifier: "%.2f")")
//                 MeshingSlider(value: $hueAdjustment, colors: [.gray, .white], range: -CGFloat.pi...CGFloat.pi)
//                     .onChange(of: hueAdjustment) { _ in applyAdjustments() }
//                     .frame(height: 70)
//             case .grain:
//                 Text("\(grain, specifier: "%.2f")")
//                 MeshingSlider(value: $grain, colors: [.gray, .white], range: -1...1)
//                     .onChange(of: grain) { _ in applyAdjustments() }
//                     .frame(height: 70)
//             }
//
//             Picker("Select Filter", selection: $selectedFilter) {
//                 ForEach(FilterType.allCases) { filter in
//                     Image(systemName: filter.rawValue).tag(filter)
//                 }
//             }
//             .pickerStyle(SegmentedPickerStyle())
//             .padding()
//             .buttonStyle(PlainButtonStyle())
//
//         }
//         .backgroundStyle(.black)
//         .onAppear {
//             applyAdjustments()
//             isAnimationTriggered = true
//         }
//     }
//
//    private func applyAdjustments() {
//        adjustedImage = applyImageAdjustments(
//            image: originalImage,
//            smoothValues: [Float(brightness), Float(contrast), Float(saturation)],
//            hueAdjustment: Float(hueAdjustment), grainIntensity: Float(grain), grainSize: 2
//        )
//    }
//}

struct CustomSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<Double>
    let stepCount: Int
    let colors: [Color]
    @State private var isDragging = false
    @State private var lastValue: Double

    init(value: Binding<CGFloat>, range: ClosedRange<Double>, stepCount: Int, colors: [Color]) {
        self._value = value
        self.colors = colors
        self.range = range
        self.stepCount = stepCount
        self._lastValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {

                Rectangle()
                    .fill(Color.adaptive)
                    .frame(height: 15)


                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<stepCount, id: \.self) { index in
                        BarIndicator(
                            height: self.getBarHeight(for: index),
                            isHighlighted: Double(index) <= self.getNormalizedValue() * Double(stepCount - 1),
                            isCurrentValue: self.isCurrentValue(index),
                            isDragging: isDragging,
                            shouldShow: Double(index) <= self.getNormalizedValue() * Double(stepCount - 1), colors: colors
                        )
                    }
                }
            }
            .frame(minHeight: 50, alignment: .bottom)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = self.getValue(geometry: geometry, dragLocation: gesture.location)
                        self.value = min(max(CGFloat(self.range.lowerBound), newValue), CGFloat(self.range.upperBound))
                        isDragging = true

                        if Int(self.value) != Int(self.lastValue) {
                            HapticManager.shared.trigger(.light)
                            self.lastValue = Double(self.value)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        HapticManager.shared.trigger(.light)
                    }
            )
        }
    }

    private func getProgress(geometry: GeometryProxy) -> CGFloat {
        let percent = (CGFloat(self.value) - CGFloat(self.range.lowerBound)) / CGFloat(self.range.upperBound - self.range.lowerBound)
        return geometry.size.width * percent
    }

    private func getValue(geometry: GeometryProxy, dragLocation: CGPoint) -> CGFloat {
        let percent = dragLocation.x / geometry.size.width
        let value = percent * CGFloat(self.range.upperBound - self.range.lowerBound) + CGFloat(self.range.lowerBound)
        return value
    }

    private func getNormalizedValue() -> Double {
        return Double((self.value - CGFloat(self.range.lowerBound)) / CGFloat(self.range.upperBound - self.range.lowerBound))
    }

    private func getBarHeight(for index: Int) -> CGFloat {
        let normalizedValue = self.getNormalizedValue()
        let stepValue = Double(index) / Double(stepCount - 1)
        let difference = abs(normalizedValue - stepValue)
        let maxHeight: CGFloat = 35
        let minHeight: CGFloat = 15

        if difference < 0.15 {
            return maxHeight - CGFloat(difference / 0.15) * (maxHeight - minHeight)
        } else {
            return minHeight
        }
    }

    private func isCurrentValue(_ index: Int) -> Bool {
        let normalizedValue = self.getNormalizedValue()
        let stepValue = Double(index) / Double(stepCount - 1)
        return abs(normalizedValue - stepValue) < (1.0 / Double(stepCount - 1)) / 2
    }
}

struct BarIndicator: View {
    let height: CGFloat
    let isHighlighted: Bool
    let isCurrentValue: Bool
    let isDragging: Bool
    let shouldShow: Bool
    let colors: [Color]

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isCurrentValue
                  ? LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
                  : (isHighlighted
                  ? LinearGradient(colors: colors.map { $0.opacity(0.75) },startPoint: .bottom, endPoint: .top)
                  : LinearGradient(colors: [.primary.opacity(0.4), .primary.opacity(0.3)], startPoint: .bottom, endPoint: .top)))
            .frame(width: 4, height: (isDragging && shouldShow) ? height : 15)
            .animation(.bouncy, value: height)
            .animation(.bouncy, value: isDragging)
            .animation(.bouncy, value: shouldShow)
    }
}

struct MeshingSlider: View {
    @Binding var value: CGFloat
    let colors: [Color]
    var range: ClosedRange<Double>

    var body: some View {
        HStack(alignment: .center) {
            CustomSlider(value: $value.animation(.bouncy), range: range, stepCount: 35, colors: colors)
        }
    }
}

class HapticManager {
    static let shared = HapticManager()

    func trigger(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: feedbackStyle)
        impact.impactOccurred()
    }
}

extension Color {
    static var adaptive: Color {
        Color(UIColor { _ in
            return .systemBackground
        })
    }
}

func applyImageAdjustments(image: UIImage, smoothValues: [Float], hueAdjustment: Float, grainIntensity: Float, grainSize: Float) -> UIImage? {
    let orientation = image.imageOrientation
    guard let ciImage = CIImage(image: image) else { return nil }
    let rotateciImage = ciImage.oriented(CGImagePropertyOrientation(image.imageOrientation))


    let colorControlsFilter = CIFilter(name: "CIColorControls")
    colorControlsFilter?.setValue(rotateciImage, forKey: kCIInputImageKey)
    colorControlsFilter?.setValue(smoothValues[0], forKey: kCIInputBrightnessKey)
    colorControlsFilter?.setValue(smoothValues[1], forKey: kCIInputContrastKey)
    colorControlsFilter?.setValue(smoothValues[2], forKey: kCIInputSaturationKey)
    guard let colorControlsOutput = colorControlsFilter?.outputImage else { return nil }

    let hueAdjustFilter = CIFilter(name: "CIHueAdjust")
    hueAdjustFilter?.setDefaults()
    hueAdjustFilter?.setValue(colorControlsOutput, forKey: kCIInputImageKey)
    hueAdjustFilter?.setValue(hueAdjustment, forKey: kCIInputAngleKey)
    guard let hueAdjustOutput = hueAdjustFilter?.outputImage else { return nil }

    let grainFilter = CIFilter(name: "CIRandomGenerator")
    guard var grainOutput = grainFilter?.outputImage else { return nil }

    let scaleFilter = CIFilter(name: "CIAffineTransform")
    let scale = CGFloat(grainSize)
    let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
    scaleFilter?.setValue(grainOutput, forKey: kCIInputImageKey)
    scaleFilter?.setValue(NSValue(cgAffineTransform: scaleTransform), forKey: kCIInputTransformKey)
    guard let scaledGrain = scaleFilter?.outputImage else { return nil }

    let cropFilter = CIFilter(name: "CICrop")
    cropFilter?.setValue(scaledGrain, forKey: kCIInputImageKey)
    cropFilter?.setValue(CIVector(cgRect: hueAdjustOutput.extent), forKey: "inputRectangle")
    guard let croppedGrain = cropFilter?.outputImage else { return nil }

    let blendFilter = CIFilter(name: "CISourceOverCompositing")
    blendFilter?.setValue(hueAdjustOutput, forKey: kCIInputBackgroundImageKey)
    blendFilter?.setValue(croppedGrain.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(grainIntensity)),
        "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
    ]), forKey: kCIInputImageKey)
    guard let blendOutput = blendFilter?.outputImage else { return nil }

    let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
    guard let cgImage = context.createCGImage(blendOutput, from: blendOutput.extent) else { return nil }

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
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.creationRequestForAsset(from: image)

                    let albumTitle = card.cardName
                    self.addImageToCustomAlbum(creationRequest, albumTitle: albumTitle)

                }) { success, error in
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

    func addImageToCustomAlbum(_ creationRequest: PHAssetCreationRequest, albumTitle: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)

        let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject

        if let album = album {
            let assetPlaceholder = creationRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
        } else {
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue:  Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
