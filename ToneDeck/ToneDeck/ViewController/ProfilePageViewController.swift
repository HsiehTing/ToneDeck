//
//  ProfilePageViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/17.
//
import SwiftUI
import FirebaseFirestore
import Kingfisher

struct ProfilePageView: View {
    @StateObject private var firestoreService = FirestoreService()
    @State var isFollowed: Bool = false
    @State var path: [ProfileDestination] = []
    @State private var fetchedCards: [Card] = []
    let userID: String
    let defaultAvatarURL = "https://example.com/default_avatar.png"  // Set a default image
    let db = Firestore.firestore()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    let fireStoreService = FirestoreService()
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Info Section
                    if let user = firestoreService.user {
                        VStack(spacing: 8) {
                            KFImage(URL(string: user.avatar))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                .shadow(radius: 10)

                            Text(user.userName)
                                .font(.title)
                                .fontWeight(.bold)

                            HStack(spacing: 24) {
                                VStack {
                                    Text("\(user.followingArray.count)")
                                        .font(.headline)
                                    Text("Following")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                VStack {
                                    Text("\(user.followerArray.count)")
                                        .font(.headline)
                                    Text("Followers")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                if userID != fromUserID {
                                    Button(action: {
                                        toggleFollow(user: user)
                                    }) {
                                        Text(isFollowed ? "Unfollow" : "Follow")
                                    }
                                } else {
                                    EmptyView()  // Return an EmptyView if no user is available
                                }
                            }
                        }
                    }
                    // Post Grid Section

                    if !firestoreService.posts.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(firestoreService.posts) { post in

                                    NavigationLink(destination: ProfilePostView(post: post, path: $path)) {
                                        KFImage(URL(string: post.imageURL))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                            }
                        }
                        .padding(.top, 16)
                    } else {
                        Text("No posts available")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")  // Add navigation title for the NavigationView
        }
        .onAppear {
            firestoreService.fetchUserData(userID: fromUserID ?? "")
            guard let user = firestoreService.user else { return }
            checkIfFollowed(user: user)

            // Fetch the cards for all posts once the view appears
            firestoreService.fetchCardsFromProfile(for: userID) { cards in
                DispatchQueue.main.async {
                    self.fetchedCards = cards
                }
            }
        }
    }
    func toggleFollow(user: User) {


        if isFollowed {
            // If already starred, remove the user's ID from the likerIDArray
            firestoreService.addUserToFollowingArray(userID: userID)
            firestoreService.addFollowNotification(user: user)
        } else {
            // If not starred, add the user's ID to the likerIDArray
            firestoreService.removeUserFromFollowingArray(userID: userID)
            firestoreService.removeFollowNotification(user: user)
        }
        isFollowed.toggle()
    }
    func checkIfFollowed(user: User) {
        // Assume we get the likerIDArray from the post
        guard let fromUserID = fromUserID else {return}
        if user.followerArray.contains(fromUserID) {
            isFollowed = true
        } else {
            isFollowed = false
        }
    }

}
enum ProfileDestination: Hashable {
    case postView
    case applyCard(card: Card)
    case visitProfile(userID: String)
}

struct ProfilePostView: View {
    let post: Post
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    let fireStoreService = FirestoreService()
    @Binding var path: [ProfileDestination]
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
//            if let card = card {
//                PostButtonsView(card: card, path: $path)
//                    .padding(.vertical, 8)
//            } else {
//                // Display loading placeholder if card is nil
//                Text("Loading card...")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                    .padding(.vertical, 8)
//            }

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
    private func toggleLike() {
        if isStarred {
            // If already starred, remove the user's ID from the likerIDArray
            removeUserFromLikerArray()
        } else {
            // If not starred, add the user's ID to the likerIDArray
            addUserToLikerArray()
        }
        isStarred.toggle()
    }
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
    private func checkIfStarred() {
        // Assume we get the likerIDArray from the post
        guard let fromUserID = fromUserID else {return}
        if post.likerIDArray.contains(fromUserID) {
            isStarred = true
        } else {
            isStarred = false
        }
    }
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
    struct PostButtonsView: View {
        let card: Card
        @Binding var path: [ProfileDestination]  // Use shared path for navigation

        var body: some View {
            HStack {
                // Button for navigating to apply card view
                Button(action: {
                    if path.last != .applyCard(card: card) {
                        path.append(.applyCard(card: card))
                    }
                    print("Navigating to applyCard with card \(card.cardName)")
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
        @Binding var path: [ProfileDestination]
        var body: some View {

            HStack {
                Button {
                    path.append(.visitProfile(userID: post.creatorID))
                } label: {
                    Text("by \(post.creatorID)")
                        .font(.caption)
                        .foregroundColor(.black)
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

    }
}

