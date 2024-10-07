//
//  FeedViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/16.
//
import SwiftUI
import FirebaseFirestore
import Kingfisher
import FirebaseCore

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
    let segments: [String] = ["For you", "Following"]
    @State private var selected: String = "For you"
    @Namespace var name
    var body: some View {
        NavigationStack(path: $path) {
            HStack{
                ForEach(segments, id: \.self) { segment in
                    Button {
                            selected = segment
                    } label: {
                        VStack{
                            Text(segment)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(selected == segment ? .white : Color(uiColor: .darkGray))
                                .animation(.easeInOut)

                            ZStack{
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                                if selected == segment {
                                    Capsule()
                                        .fill(Color.secondary)
                                        .matchedGeometryEffect(id: "Tab", in: name)
                                        .frame(width: 100, height: 2)
                                        .animation(.easeInOut)

                                }
                            }
                        }

                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 40) {
                    ForEach(
                        firestoreService.posts
                        
                            .filter { post in
                                // 确保 post.creatorID 不在 blockUserArray 中

                                guard let blockUserArray = firestoreService.user?.blockUserArray else {
                                    return true
                                }
                                guard let followingUserArray = firestoreService.user?.followingArray else {
                                    return true
                                }
                                if selected == segments[0] {
                                               return !blockUserArray.contains(post.creatorID) && post.isPrivate == false
                                           } else {
                                               return !blockUserArray.contains(post.creatorID) && followingUserArray.contains(post.creatorID)
                                           }

                            }
                            .sorted(by: { ($0.createdTime.dateValue()) > ($1.createdTime.dateValue()) })
                    ) { post in
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
                    firestoreService.fetchUserData(userID: fromUserID ?? "")
                }
                .navigationBarItems(trailing: Button(action: {
                    if path.last != .addPost {
                        path.append(.addPost)
                    }
                    print("Navigating to addPost")  // Debugging print
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.cyan)
                       

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
                .frame(maxWidth: .infinity, maxHeight: 400)
                .padding()
                .clipped()
                .overlay( HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        if let card = card {
                            PostButtonsView(card: card, path: $path)

                        }

                    }
                }
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding([.leading, .trailing])

                )
            HStack {
                Spacer()
                Button(action: {
                    toggleLike()

                }) {
                    Image(systemName: isStarred ?"capsule.fill" :"capsule" )
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(isStarred ? .cyan  : .white) // Change color based on state
                        .clipShape(Circle())

                }
                .buttonStyle(PlainButtonStyle())
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
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $isCommentViewPresented) {
                    CommentView(post: post, postID: post.id, userID: fromUserID ?? "", userAvatarURL: userAvatarURL)
                }
            }
            // Display Post Text
            Text(post.text)
                .font(.title)
                .padding()
            PostInfoView(post: post, path: $path)

        }
        .background(Color.black)
        .frame(maxWidth: .infinity, maxHeight: 800)
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
                    .font(.title3)
                    .cornerRadius(10)
                    .foregroundColor(.white)

            }
            .buttonStyle(PlainButtonStyle())
            Spacer()

            // Button for navigating to apply card view using image
            Button(action: {
                path.append(.applyCard(card: card))  // Navigate to applyCard view
                print("Navigating to applyCard with image for card \(card.cardName)")  // Debugging print
            }) {
                KFImage(URL(string: card.imageURL))
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(10)

                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white, lineWidth: 2)
                    )


            }

            .buttonStyle(PlainButtonStyle())
        }
        .padding(.bottom, 30)
        .padding(.trailing, 15)
        .padding(.leading, 15)
    }
}

struct PostInfoView: View {
    let post: Post
    @Binding var path: [FeedDestination]
    let db = Firestore.firestore()
    @State private var userName: String = ""
    var body: some View {

        VStack {
            Button {
                path.append(.visitProfile(userID: post.creatorID))
            } label: {
                Text(userName)
                    .font(.caption)
                    .foregroundColor(.white)

                Spacer()
                Text("\(formattedDate(from: post.createdTime))")
                    .font(.caption)
                    .foregroundColor(.gray)

            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .onAppear {
            fetchUserName(for: post.creatorID)
        }
    }
    func fetchUserName(for userID: String) {
        let userRef = db.collection("users").whereField("id", isEqualTo: userID)
        userRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
            } else if let snapshot = snapshot, let document = snapshot.documents.first {
                if let user = try? document.data(as: User.self) {
                    userName = user.userName  // 更新用户名
                }
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
#Preview {
    FeedView()
}
