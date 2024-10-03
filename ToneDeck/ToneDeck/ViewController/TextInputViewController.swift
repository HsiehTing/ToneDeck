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
    var onDismiss: (() -> Void)?
    @Binding var path: [FeedDestination]
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
                .cornerRadius(20)
                .padding()
            Button(action: {
                publishPost()
            }) {
                Text("Publish")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .navigationTitle("Add Post")
        .background(
            Color.black
                        .onTapGesture {
                            UIApplication.shared.endEditing()
                        }
                )
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
            "createdTime": Timestamp(),
            "cardID": photo.cardID,
            "photoIDArray": [photo.id],
            "isPrivate": UserDefaults.standard.bool(forKey: "privacyStatus"),
            "likerIDArray": [],
            "id": postID,
            "commentArray": []
        ]
        document.setData(postData) { error in
            if let error = error {
                print("Error publishing post: \(error)")
            } else {
                print("Post published successfully!")
                let userDocument = users.whereField("id", isEqualTo: photo.creatorID)
                userDocument.addSnapshotListener { snapshot, error in
                    if let error = error {
                        print(error)
                    }
                    guard let documents = snapshot?.documents else {
                        print("No posts found.")
                        return
                    }
                    for document in documents {
                        document.reference.updateData([
                            "postIDArray": FieldValue.arrayUnion([postID]) // Add postID to user's postIDArray
                        ]) { error in
                            if let error = error {
                                print("Error updating user's postIDArray: \(error)")
                            } else {
                                print("User's postIDArray updated successfully!")
                            }
                        }
                    }


                }
                onDismiss?()
                path.removeAll()
                presentationMode.wrappedValue.dismiss() // 發佈成功後返回前一頁
            }
        }  
    }
}

