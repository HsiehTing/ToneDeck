//
//  CommentViewCOntroller.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/20.
//

import SwiftUI
import Firebase
import Kingfisher

struct CommentView: View {
    @State private var comments: [Comment] = []  // Local state to store comments
    @State private var newCommentText: String = ""
    let post: Post
    let postID: String
    let userID: String
    let userAvatarURL: String  // URL for the avatar from the "users" collection
    let fireStoreService = FirestoreService()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")

    var body: some View {
        VStack {
            // Display comments list
            ScrollView {
                ForEach(comments, id: \.createdTime) { comment in
                    HStack(alignment: .center) {
                        Text(comment.text)
                            .font(.body)
                        Text(comment.userID)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                    Divider()
                }
            }

            // Text field and send button
            HStack {
                // User avatar
                KFImage(URL(string: userAvatarURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                // Comment input field
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)

                // Send button
                Button(action: {
                    sendComment()
                }) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                }
            }
            .padding()
        }
        .onAppear {
            loadComments()  // Fetch comments when the view appears
            fireStoreService.fetchUserData(userID: fromUserID ?? "")
        }
        .navigationTitle("comments")
    }

    // Function to load comments from Firestore
    private func loadComments() {
        let postRef = Firestore.firestore().collection("posts").document(postID)
        postRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                if let commentArray = data?["commentArray"] as? [[String: Any]] {
                    self.comments = commentArray.compactMap { dict in
                        guard let text = dict["text"] as? String,
                              let userID = dict["userID"] as? String,
                              let createdTime = dict["createdTime"] as? Timestamp else { return nil }
                        return Comment(createdTime: createdTime, text: text, userID: userID)
                    }
                }
            }
        }
    }

    // Function to send the new comment to Firestore
    private func sendComment() {
        guard !newCommentText.isEmpty else { return }

        let newComment = Comment(createdTime: Timestamp(), text: newCommentText, userID: userID)
        let commentDict: [String: Any] = [
            "createdTime": newComment.createdTime as Any,
            "text": newComment.text,
            "userID": newComment.userID
        ]

        let postRef = Firestore.firestore().collection("posts").document(postID)
        postRef.updateData([
            "commentArray": FieldValue.arrayUnion([commentDict])
        ]) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                newCommentText = ""  // Clear input field after sending
                loadComments()  // Refresh comments
            }
        }
        let notifications = Firestore.firestore().collection("notifications")
        let user = fireStoreService.user
        let document = notifications.document()
        guard let user = user else {return}
        let data: [String: Any] = [
             "id": document.documentID,
             "fromUserPhoto": user.avatar,
             "from": fromUserID,
             "to": post.creatorID,
             "postImage": post.imageURL,
             "type":  NotificationType.comment.rawValue,
             "createdTime": Timestamp()
        ]
        document.setData(data)
    }
}

