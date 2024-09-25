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

struct AddCardViewController: View {
    @Binding var path: [CardDestination]
    @State private var cardName: String = ""
    @State private var selectedImage: UIImage?
    @State private var pickerImage: PhotosPickerItem?
    var body: some View {
        VStack {
            // TextField for Card Name
            TextField("Enter Card Name", text: $cardName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            // Picker for selecting an image from photo album
            PhotosPicker(selection: $pickerImage, matching: .images, photoLibrary: .shared()) {
                Text("Select Image")
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .onChange(of: pickerImage) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            // Display the selected image
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            // Button to submit the card data
            Button(action: {
                addCard()
            }) {
                Text("Add Card")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            Spacer()
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
        //let userName = "User123"
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
                    let document = cards.document()
                    let cardData: [String: Any] = [
                        "id": document.documentID,
                        "creatorID": fromUserID ?? "",
                        "cardName": cardName,
                        "createdTime": timeStamp,
                        "filterData": filterData,
                        "imageURL": imageURL
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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

