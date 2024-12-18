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
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    let post: Post
    let postID: String
    let userID: String
    let userAvatarURL: String
    let fireStoreService = FirestoreService()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")

    var body: some View {
        VStack {
            Text("Comments")
                .frame(height: 100)
                .font(.title)

            ScrollView {
                ForEach(comments, id: \.createdTime) { comment in
                    CommentRow(comment: comment)
                }
                Spacer(minLength: 50)
            }

            HStack {
                KFImage(URL(string: userAvatarURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 80)

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
            loadComments()
            fireStoreService.fetchUserData(userID: fromUserID ?? "")
        }
        .background(
            Color.black
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
        )
    }
    struct CommentRow: View {
        let comment: Comment
        @State private var user: User?
        var body: some View {
            HStack(alignment: .center) {
                if let user = user {
                    Text(user.userName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(comment.text)
                    .font(.body)
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .onAppear {
                fetchUser(fromUserID: comment.userID)
            }
            .background(
                Color.black
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
            )
        }

        func fetchUser(fromUserID: String) {
            let db = Firestore.firestore()
            let userRef = db.collection("users").whereField("id", isEqualTo: fromUserID)
            userRef.addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching user data: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    print("User not found")
                    return
                }
                let document = documents[0]
                do {
                    self.user = try document.data(as: User.self)
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
        }
    }
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
                newCommentText = ""
                loadComments()  
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

#Preview {
    FeedView()
}
