//
//  FeedViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/16.
//
import SwiftUI
import FirebaseFirestore
import Kingfisher

// 定義導航目的地
enum FeedDestination: Hashable {
    case addPost
    case applyCard(card: Card)
    case visitProfile(userID: String)
}
struct Post: Identifiable, Codable {
    var id: String
    var text: String
    var imageURL: String
    var creatorID: String
    var createdTime: Timestamp
    var photoIDArray: [String]
    var cardID: String?
    var commentArray: [Comment]
    var isPrivate: Bool
    var likerIDArray: [String]
}
struct Comment: Codable {
    var createdTime: Timestamp?
    var text: String
    var userID: String
}

struct FeedView: View {
    @StateObject private var firestoreService = FirestoreService()
    @State private var path = [FeedDestination]()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 40) {
                    ForEach(firestoreService.posts.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  })) { post in
                        if let cardID = post.cardID,
                           let card = firestoreService.cardsDict[cardID] {
                            PostView(post: post, card: card, path: $path)
                        } else {
                            PostView(post: post, card: nil, path: $path)
                        }
                    }
                }
                .navigationTitle("Feed")
                .onAppear {
                    firestoreService.fetchPosts()  // Load posts on view appear
                }
                .navigationBarItems(trailing: Button(action: {
                    if path.last != .addPost {
                        path.append(.addPost)
                    }
                    print("Navigating to addPost")  // Debugging print
                }) {
                    Image(systemName: "plus")
                })
                .navigationDestination(for: FeedDestination.self) { destination in
                    switch destination {
                    case .addPost:
                        PhotoGridView(path: $path)

                    case .applyCard(let card):
                        SecondApplyCardViewControllerWrapper(card: card)

                    case .visitProfile(let postCreatorID):
                        ProfilePageView(userID: postCreatorID)
                            .onDisappear {
                                path.removeAll(where: { $0 == .addPost })
                            }
                    }
                }
            }
        }
    }
}

    struct PostView: View {
        let post: Post
        let card: Card? // Optional card
        let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
        let fireStoreService = FirestoreService()
        @Binding var path: [FeedDestination]
        @State private var isStarred: Bool = false
        @State private var isCommentViewPresented: Bool = false
        @State private var userAvatarURL: String = ""
        var body: some View {
            VStack(alignment: .leading) {
                // Display Post Image
                KFImage(URL(string: post.imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 600)
                    .clipped()

                // Display card buttons if the card exists
                if let card = card {
                    PostButtonsView(card: card, path: $path)
                        .padding(.vertical, 8)
                } else {
                    // Display loading placeholder if card is nil
                    Text("Loading card...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }

                // Display Post Text
                Text(post.text)
                    .font(.body)
                    .padding([.top, .leading, .trailing])

                // Display Creator ID and Time
                PostInfoView(post: post, path: $path)
            }
            .background(Color.black)
            .frame(maxWidth: .infinity, maxHeight: 800)
            .overlay( HStack {
                Spacer()
                VStack {
                    Button(action: {
                        toggleLike()

                    }) {
                        Image(systemName: "star.fill")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(isStarred ? .yellow : .white) // Change color based on state
                            .clipShape(Circle())
                    }
                    .padding(4)

                    Button(action: {
                        loadUserAvatar()  // Load user avatar before presenting the view
                        isCommentViewPresented = true
                    }) {
                        Image(systemName: "bubble.right")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(4)
                    .sheet(isPresented: $isCommentViewPresented) {
                        CommentView(post: post, postID: post.id, userID: fromUserID ?? "", userAvatarURL: userAvatarURL)
                    }
                }
            }
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding([.leading, .trailing])
            )
            .onAppear {
                fireStoreService.fetchUserData(userID: fromUserID ?? "")
                checkIfStarred()
            }
        }

        func toggleLike() {
            if isStarred {
                // If already starred, remove the user's ID from the likerIDArray
                removeUserFromLikerArray()
            } else {
                // If not starred, add the user's ID to the likerIDArray
                addUserToLikerArray()
            }
            isStarred.toggle()
        }
        func checkIfStarred() {
            // Assume we get the likerIDArray from the post
            guard let fromUserID = fromUserID else {return}
            if post.likerIDArray.contains(fromUserID) {
                isStarred = true
            } else {
                isStarred = false
            }
        }

        // Function to add the user to the likerIDArray in the posts collection
        func addUserToLikerArray() {

            guard let fromUserID = fromUserID else {return}
            let postRef = Firestore.firestore().collection("posts").document(post.id)
            postRef.updateData([
                "likerIDArray": FieldValue.arrayUnion([fromUserID])
            ]) { error in
                if let error = error {
                    print("Error adding user to likerIDArray: \(error)")
                } else {
                    print("User added to likerIDArray successfully.")
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
                "type": NotificationType.like.rawValue,
                "createdTime": Timestamp()
            ]
            document.setData(data)
        }

        // Function to remove the user from the likerIDArray in the posts collection
        func removeUserFromLikerArray() {
            // Firestore logic to update likerIDArray
            guard let fromUserID = fromUserID else {return}

            let postRef = Firestore.firestore().collection("posts").document(post.id)
            postRef.updateData([
                "likerIDArray": FieldValue.arrayRemove([fromUserID])
            ]) { error in
                if let error = error {
                    print("Error removing user from likerIDArray: \(error)")
                } else {
                    print("User removed from likerIDArray successfully.")
                }
            }
            let user = fireStoreService.user
            guard let user = user else {return}
            let likeRef = Firestore.firestore().collection("notifications").whereField("from", isEqualTo: user.id).whereField("to", isEqualTo: post.creatorID).whereField("type", isEqualTo: "like")
            likeRef.getDocuments { query, error in
                guard let documents = query?.documents else {return}
                for document in documents {
                    document.reference.delete()
                }
            }
        }
        func loadUserAvatar() {
            guard let fromUserID = fromUserID else {return}
            let userRef = Firestore.firestore().collection("users").document(fromUserID)
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    self.userAvatarURL = document.data()?["avatarURL"] as? String ?? ""
                }
            }
        }
    }


struct PostButtonsView: View {
    let card: Card
    @Binding var path: [FeedDestination]  // Use shared path for navigation

    var body: some View {
        HStack {
            // Button for navigating to apply card view
            Button(action: {
                if path.last != .applyCard(card: card) { // 防止重复导航
                    path.append(.applyCard(card: card))
                }
                print("Navigating to applyCard with card \(card.cardName)")  // Debugging print
            }) {
                Text(card.cardName)
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            Spacer()

            // Button for navigating to apply card view using image
            Button(action: {
                path.append(.applyCard(card: card))  // Navigate to applyCard view
                print("Navigating to applyCard with image for card \(card.cardName)")  // Debugging print
            }) {
                KFImage(URL(string: card.avatar))
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

struct PostInfoView: View {
    let post: Post
    @Binding var path: [FeedDestination]
    var body: some View {

        HStack {
            Button {
                path.append(.visitProfile(userID: post.creatorID))
            } label: {
                Text("by \(post.creatorID)")
                    .font(.caption)
                    .foregroundColor(.black) // 顯示為可點擊的藍色
                Spacer()
                Text("\(formattedDate(from: post.createdTime))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding([.leading, .trailing, .bottom])
            }
        }
    }
    func formattedDate(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue() // Convert Timestamp to Date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // Set date format (e.g., "Sep 24, 2024")
        formatter.timeStyle = .none   // Only show date, no time
        return formatter.string(from: date) // Convert Date to String
    }
    struct FeedView_Previews: PreviewProvider {
        static var previews: some View {
            FeedView()
        }

    }
}
