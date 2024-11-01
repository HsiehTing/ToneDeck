//
//  AddCardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import Kingfisher
import AlertKit
class AddCardViewModel: ObservableObject {
    @Binding var path: [CardDestination]
    @Published var cardName: String = ""
    @Published var selectedImage: UIImage?
    @Published var isFillOutInfo: Bool = false
    @Published var isShowingPhotoPicker: Bool = false
    @Published var showingTextAlert: Bool = false
    @Published var showingCompleteAlert: Bool = false
    init(path: Binding<[CardDestination]>) {
            _path = path
        }
    let alertView = AlertAppleMusic17View(title: "Card name error", subtitle: " should not be more than 14 texts", icon: .error)
    let successView = AlertAppleMusic17View(title: "Add card complete", subtitle: nil, icon: .done)


    func addCard() {
        guard let image = selectedImage, !cardName.isEmpty else {
            print("Card name or image is missing")
            return
        }

        let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
        let timeStamp = Date()
        let histogram = ImageHistogramCalculator()
        let filterHistogramData = histogram.calculateHistogram(for: image)
        let filterData = [calculateBrightness(from: filterHistogramData),
                          calculateContrastFromHistogram(histogramData: filterHistogramData),
                          calculateSaturation(from: filterHistogramData),
                          getDominantColor(from: image)]

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Unable to get image data")
            return
        }

        let storageRef = Storage.storage().reference().child("cards/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
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
                    self.saveCardData(imageURL: imageURL, filterData: filterData, fromUserID: fromUserID ?? "", timeStamp: timeStamp)
                }
            }
        }
    }

    private func saveCardData(imageURL: String, filterData: [Any], fromUserID: String, timeStamp: Date) {
        let db = Firestore.firestore()
        let cards = db.collection("cards")
        if let selectedImage = selectedImage {
            guard let dominantColor = dominantColor else {return}
           let rgbaComponents = dominantColor.rgbaComponents
           let dominantColorData: [String: Any] = [
                "red": rgbaComponents.red,
                "green": rgbaComponents.green,
                "blue": rgbaComponents.blue,
                "alpha": rgbaComponents.alpha
            ]
            let document = cards.document()
            let cardData: [String: Any] = [
                "id": document.documentID,
                "creatorID": fromUserID,
                "cardName": cardName,
                "createdTime": timeStamp,
                "filterData": filterData,
                "imageURL": imageURL,
                "dominantColor": dominantColorData
            ]
            document.setData(cardData) { error in
                if let error = error {
                    print("Error saving card: \(error)")
                } else {
                    print("Card successfully saved!")
                    if !self.path.isEmpty {
                        self.path.removeLast()
                    } else {
                        print("Path is already empty, cannot remove last.")
                    }
                }
            }
        }
    }

    func validateCardName() {
        if cardName.count > 14 {
            showingTextAlert = true
        } else if isFillOutInfo {
            showingCompleteAlert = true
            addCard()
        } else {
            isShowingPhotoPicker = true
        }
    }
}

struct AddCardViewController: View {

    @Binding var path: [CardDestination]
    @ObservedObject var viewModel: AddCardViewModel
    init(path: Binding<[CardDestination]>) {
        self._path = path
        self.viewModel = AddCardViewModel(path: path)
    }
    var body: some View {
        VStack {
            TextField("Enter Card Name", text: $viewModel.cardName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: .infinity)
                    .padding()
                    .onTapGesture {
                        viewModel.isShowingPhotoPicker = true
                    }
            }

            Button(action: {
                viewModel.validateCardName()
            }) {
                Image(systemName: !viewModel.cardName.isEmpty && viewModel.selectedImage != nil ? "camera.filters" : "camera.metering.center.weighted.average")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.gray)
                    .cornerRadius(10)
                    .alert(isPresent: $viewModel.showingTextAlert, view: viewModel.alertView)
                    .alert(isPresent: $viewModel.showingCompleteAlert, view: viewModel.successView)
            }
            .buttonStyle(PlainButtonStyle())
            .contentTransition(.symbolEffect(.replace, options: .nonRepeating))
        }
        .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
            ImagePicker(image: $viewModel.selectedImage, isPresented: $viewModel.isShowingPhotoPicker)
        }
        .onChange(of: viewModel.selectedImage) { _ in
            viewModel.isFillOutInfo = true
        }
        .padding()
        .navigationTitle("Add Card")
        .background(
            Color.black
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
        )
    }
}
#Preview {
    CardViewController()
}
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
