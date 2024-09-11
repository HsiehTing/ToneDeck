//
//  CardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct CardViewController: View {
    var body: some View {
        VStack {
            Text("This is the Card View Controller")
                .font(.largeTitle)
                .padding()
        }
        .navigationTitle("Cards")
        .navigationBarItems(trailing: Button(action: {
            // Add action for the "+" button here
            print("+ button tapped")
            addCard()
        }) {
            Image(systemName: "plus")
        })
    }
}


func addCard() {
       // Mock data for testing
       let userName = "User123"
       let cardName = "New Card"
       let timeStamp = Date()
       let histogramData = [0.1, 0.2, 0.3] // Just an example
       let image = UIImage(systemName: "photo") // Replace with real image
    // 將資料儲存到 Firestore
    let db = Firestore.firestore()
    let cardData: [String: Any] = [
        "userName": userName,
        "cardName": cardName,
        "timeStamp": timeStamp,
        "histogramData": histogramData,
        //"imageURL": imageURL
    ]
    
    db.collection("cards").addDocument(data: cardData) { error in
        if let error = error {
            print("Error saving card: \(error)")
        } else {
            print("Card successfully saved!")
        }
    }

       // 儲存圖片到 Firebase Storage
       guard let image = image,
             let imageData = image.jpegData(compressionQuality: 0.8) else {
           print("Unable to get image data")
           return
       }
       
       let storageRef = Storage.storage().reference().child("cards/\(UUID().uuidString).jpg")
       
       storageRef.putData(imageData, metadata: nil) { metadata, error in
           if let error = error {
               print("Error uploading image: \(error)")
               return
           }
           
           // 獲取圖片的 URL
           storageRef.downloadURL { url, error in
               if let error = error {
                   print("Error getting image URL: \(error)")
                   return
               }
               
               if let imageURL = url?.absoluteString {
               }
           }
       }
   }
