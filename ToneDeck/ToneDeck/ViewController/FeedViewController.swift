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
import AlertKit

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
    @State private var blockPostsArray = [String]()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    let segments: [String] = ["For you", "Following"]
    @State private var selected: String = "For you"
    @Namespace var name

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack {
                    ForEach(segments, id: \.self) { segment in
                        Button {
                            selected = segment
                        } label: {
                            VStack {
                                Text(segment)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(selected == segment ? .white : Color(uiColor: .darkGray))
                                    .animation(.easeInOut)

                                ZStack {
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
                    LazyVStack(alignment: .leading, spacing: 10) {
                        let filteredPosts = firestoreService.posts
                            .filter { post in
                                !blockPostsArray.contains(post.id ?? "") &&
                                {
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
                                }()
                            }
                            .sorted(by: { ($0.createdTime.dateValue()) > ($1.createdTime.dateValue()) })

                        ForEach(Array(filteredPosts.enumerated()), id: \.element.id) { _, post in
                            VStack {
                                if let cardID = post.cardID,
                                   let card = firestoreService.cardsDict[cardID] {
                                    PostView(viewModel: PostViewModel(post: post, card: card, blockPostsArray: blockPostsArray), path: $path)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Feed")
                .onAppear {
                    firestoreService.fetchPosts()
                    firestoreService.fetchUserData(userID: fromUserID ?? "")
                    loadBlockedPosts()
                }
                .navigationBarItems(trailing: Button(action: {
                    if path.last != .addPost {
                        path.append(.addPost)
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.cyan)
                })
                .navigationDestination(for: FeedDestination.self) { destination in
                    switch destination {
                    case .addPost:
                        PhotoGridView(path: $path)
                    case .applyCard(let card):
                        ApplyCardView(card: card, path: $path)
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

    private func loadBlockedPosts() {
        if let blockedPosts = UserDefaults.standard.array(forKey: "blockPostsArray") as? [String] {
            blockPostsArray = blockedPosts
        }
    }
}
class PostViewModel: ObservableObject {

    @Published var post: Post
    @Published var card: Card
    @Published var isStarred: Bool = false
    @Published var isCommentViewPresented: Bool = false
    @Published var userAvatarURL: String = ""
    @Published var showReportAlert = false
    @Published var blockPostsArray: [String]
     let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
     let fireStoreService = FirestoreService()
    init(post: Post, card: Card, isStarred: Bool = false, isCommentViewPresented: Bool = false, userAvatarURL: String = "", showReportAlert: Bool = false, blockPostsArray: [String]) {
        self.post = post
        self.card = card
        self.isStarred = isStarred
        self.isCommentViewPresented = isCommentViewPresented
        self.userAvatarURL = userAvatarURL
        self.showReportAlert = showReportAlert
        self.blockPostsArray = blockPostsArray
    }
    func toggleLike() {
        if isStarred {
            removeUserFromLikerArray()
        } else {
            addUserToLikerArray()
        }
        isStarred.toggle()
    }
    func checkIfStarred() {
       // guard let post = post else {return}
        guard let fromUserID = fromUserID else {return}
        if post.likerIDArray.contains(fromUserID) {
            isStarred = true
        } else {
            isStarred = false
        }
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

    func removeUserFromLikerArray() {
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
     func reportPost(post: Post) {
        let postID = post.id
        blockPostsArray.append(postID)
        UserDefaults.standard.set(blockPostsArray, forKey: "blockPostsArray")

    }

}
struct PostView: View {

    @ObservedObject var viewModel: PostViewModel

    @Binding var path: [FeedDestination]
    let alertcopyView = AlertAppleMusic17View(title: nil, subtitle: "Thanks for reporting this post", icon: .done)

    var body: some View {
        VStack(alignment: .leading) {

            KFImage(URL(string: viewModel.post.imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .padding()
                    .clipped()
                    .overlay( HStack {
                        Spacer()
                        VStack {
                            Spacer()

                            PostButtonsView(card: viewModel.card, path: $path)

                        }
                    }
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding([.leading, .trailing])

                    )

            HStack {
                if viewModel.post.creatorID != viewModel.fromUserID {
                        HStack {
                            Menu {
                                Button {
                                    viewModel.reportPost(post: viewModel.post)
                                    viewModel.showReportAlert = true
                                } label: {
                                    Text("Report Post")
                                        .alert(isPresent: $viewModel.showReportAlert, view: alertcopyView)

                                }

                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())

                            }
                            .padding(.trailing)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                Spacer()
                Button(action: {
                    viewModel.toggleLike()
                }) {
                    Image(systemName: viewModel.isStarred ?"capsule.fill" :"capsule" )
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(viewModel.isStarred ? .cyan  : .white) // Change color based on state
                        .clipShape(Circle())

                }
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    viewModel.loadUserAvatar()  // Load user avatar before presenting the view
                    viewModel.isCommentViewPresented = true
                }) {
                    Image(systemName: "bubble.right")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Circle())

                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $viewModel.isCommentViewPresented) {
                    CommentView(post: viewModel.post, postID: viewModel.post.id, userID: viewModel.fromUserID ?? "", userAvatarURL: viewModel.userAvatarURL)

                }
            }
            Text(viewModel.post.text)
                    .font(.caption)
                    .padding()

            PostInfoView(post: viewModel.post, path: $path)

        }
        .background(Color.black)
        .frame(maxWidth: .infinity, maxHeight: 800)
        .onAppear {
            viewModel.fireStoreService.fetchUserData(userID: viewModel.fromUserID ?? "")
            viewModel.checkIfStarred()
        }
    }
}
struct PostButtonsView: View {
    let card: Card
    @Binding var path: [FeedDestination]

    var body: some View {
        HStack {

            Button(action: {
                if path.last != .applyCard(card: card) {
                    path.append(.applyCard(card: card))
                }
                print("Navigating to applyCard with card \(card.cardName)")  
            }) {
                Text(card.cardName)
                    .font(.title3)
                    .cornerRadius(10)
                    .foregroundColor(.white)

            }
            .buttonStyle(PlainButtonStyle())
            Spacer()

            Button(action: {
                path.append(.applyCard(card: card))
                print("Navigating to applyCard with image for card \(card.cardName)")
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
                print("=======")
            } label: {
                Text(userName)
                    .font(.caption)
                    .foregroundColor(.white)

                Spacer()
                Text("\(formattedDate(from: post.createdTime))")
                    .font(.caption)
                    .foregroundColor(.gray)

            }
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
                    userName = user.userName
                }
            }
        }
    }
    func formattedDate(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
