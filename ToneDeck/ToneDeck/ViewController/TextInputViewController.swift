//
//  TextInputViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/16.
//

import SwiftUI
import FirebaseFirestore
import Kingfisher

struct TextInputView: View {
    @State private var postText: String = ""
    var photo: Photo

    @Environment(\.presentationMode) var presentationMode // 讓視圖能夠返回前一頁

    var body: some View {
        VStack {
            KFImage(URL(string: photo.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .padding()
            TextEditor(text: $postText)
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .padding()
            Button(action: {
                publishPost()
            }) {
                Text("Publish")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Add Post")
    }
    
    // 將貼文儲存到 Firebase Firestore
    func publishPost() {
        let db = Firestore.firestore()
        let posts = Firestore.firestore().collection("posts")
        let users = Firestore.firestore().collection("users")
        let document = posts.document()
        let postID = document.documentID
        let postData: [String: Any] = [
            "imageURL": photo.imageURL,
            "text": postText,
            "creatorID": photo.creatorID,
            "createdTime": Date(),
            "cardID": photo.cardID,
            "photoIDArray": [photo.id],
            "isPrivate": "false",
            "likerIDArray": [],
            "id": postID,
            "commentArray": ["userID" : [],
                             "text": "",
                             "createdTime": "",
                            ]
        ]
        document.setData(postData) { error in
            if let error = error {
                print("Error publishing post: \(error)")
            } else {
                print("Post published successfully!")
                let userDocument = users.document(photo.creatorID)
                userDocument.updateData([
                    "postIDArray": FieldValue.arrayUnion([postID]) // Add postID to user's postIDArray
                ]) { error in
                    if let error = error {
                        print("Error updating user's postIDArray: \(error)")
                    } else {
                        print("User's postIDArray updated successfully!")
                    }
                }
                presentationMode.wrappedValue.dismiss() // 發佈成功後返回前一頁
            }
        }  
    }
}
