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
    
    @Binding var path: [String]
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
    }
    
    // MARK: - Add Card Action
    func addCard() {
        guard let image = selectedImage, !cardName.isEmpty else {
            print("Card name or image is missing")
            return
        }
        
        // Mock data for testing
        let userName = "User123"
        let timeStamp = Date()
        let histogramData = [0.1, 0.2, 0.3] // Just an example
        
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
                    let cardData: [String: Any] = [
                        "userName": userName,
                        "cardName": cardName,
                        "timeStamp": timeStamp,
                        "histogramData": histogramData,
                        "imageURL": imageURL
                    ]
                    
                    db.collection("cards").addDocument(data: cardData) { error in
                        if let error = error {
                            print("Error saving card: \(error)")
                        } else {
                            print("Card successfully saved!")
                            path.removeLast()
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

