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

struct AddCardViewController: View {
    @Binding var path: [CardDestination]
    @State private var cardName: String = ""
    @State private var selectedImage: UIImage?
    @State private var isShowingPhotoPicker = false
    @State private var isFillOutInfo = false
    @State private var showingTextAlert = false
    @State private var showingCompleteAlert = false
    let alertView = AlertAppleMusic17View(title: "Card name error", subtitle: " should not be more than 14 texts", icon: .error)
    let successView = AlertAppleMusic17View(title: "Add card complete", subtitle: nil, icon: .done)
    var body: some View {
        VStack {
            TextField("Enter Card Name", text: $cardName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: .infinity)
                    .padding()
                    .onTapGesture {
                        isShowingPhotoPicker = true
                    }
            }

            Button(action: {
                if cardName.count > 14 {
                        // 顯示 alert
                    showingTextAlert = true
                    } else {
                        // 如果資料已填寫完成，執行 addCard()
                        if isFillOutInfo {
                            showingCompleteAlert = true
                            addCard()
                        } else {
                            isShowingPhotoPicker = true
                        }
                    }
                successView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                successView.titleLabel?.textColor = .white
                alertView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                   alertView.titleLabel?.textColor = .white
            }) { Image(systemName: !cardName.isEmpty && selectedImage != nil ? "camera.filters" : "camera.metering.center.weighted.average")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.gray)
                    .cornerRadius(10)
                    .alert(isPresent: $showingTextAlert, view: alertView)
                    .alert(isPresent: $showingCompleteAlert, view: successView)
            }
            
            .buttonStyle(PlainButtonStyle())
            .contentTransition(.symbolEffect(.replace, options: .nonRepeating))
        }
        .sheet(isPresented: $isShowingPhotoPicker) {
            ImagePicker(image: $selectedImage, isPresented: $isShowingPhotoPicker)
        }
        .onChange(of: selectedImage) { _ in
            isFillOutInfo = true
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

    // MARK: - Add Card Action
    func addCard() {
        guard let image = selectedImage, !cardName.isEmpty else {
            print("Card name or image is missing")
            return
        }
        // Mock data for testing
        let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
        let timeStamp = Date()
        let histogram = ImageHistogramCalculator()
        let filterHistogramData = histogram.calculateHistogram(for: image)
        let filterData = [calculateBrightness(from: filterHistogramData),
                          calculateContrastFromHistogram(histogramData: filterHistogramData),
                          calculateSaturation(from: filterHistogramData),
                          getDominantColor(from: image)]
        // Save the image to Firebase Storage
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
            // Get the image URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting image URL: \(error)")
                    return
                }
                if let imageURL = url?.absoluteString {
                    // Save the card data to Firestore
                    let db = Firestore.firestore()
                    let cards = Firestore.firestore().collection("cards")
                    guard let dominantColor = dominantColor else {return}
                    let rgbaComponents = dominantColor.rgbaComponents
                    let document = cards.document()
                    let dominantColorData: [String: Any] = [
                        "red": rgbaComponents.red,
                        "green": rgbaComponents.green,
                        "blue": rgbaComponents.blue,
                        "alpha": rgbaComponents.alpha
                    ]
                    let cardData: [String: Any] = [
                        "id": document.documentID,
                        "creatorID": fromUserID ?? "",
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
                            if !path.isEmpty {
                                path.removeLast() // Remove last only if the path array is not empty
                            } else {
                                print("Path is already empty, cannot remove last.")
                            }
                        }
                    }
                }
            }
        }
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
