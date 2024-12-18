//
//  ProfilePageViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/17.
//
import SwiftUI
import FirebaseFirestore
import Kingfisher
import AlertKit

struct ProfilePageView: View {

    @StateObject private var firestoreService = FirestoreService()
    @State var isFollowed: Bool = false
    @State var path: [ProfileDestination] = []
    @State private var fetchedPosts: [Post] = []
    @State var userData: User? = nil
    @State private var showBlockAlert = false
    @State private var showReportAlert = false
    let userID: String
    let db = Firestore.firestore()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    let fireStoreService = FirestoreService()
    let alertView = AlertAppleMusic17View(title: "User blocked", subtitle: "You will not see the posts from this user", icon: .done)
    let reportView = AlertAppleMusic17View(title: "Report received", subtitle: "We will work on this ASAP", icon: .done)
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Info Section
                    if let user = firestoreService.user {
                        VStack(spacing: 8) {
                            KFImage(URL(string: user.avatar))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                .shadow(radius: 10)
                            Text(user.userName)
                                .font(.title)
                                .fontWeight(.bold)

                            HStack(spacing: 24) {
                                VStack {
                                    Text("\(user.followingArray.count - 1)")
                                        .font(.headline)
                                    Text("Following")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                VStack {
                                    Text("\(user.followerArray.count - 1)")
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
                                            .font(.callout)
                                            .frame(width: isFollowed ?  80 : 50)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(isFollowed ? .gray : .blue)
                                } else {
                                    EmptyView()
                                }
                            }
                        }
                    }
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
                            .buttonStyle(PlainButtonStyle())
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
        }
        .onAppear {
            firestoreService.fetchProfile(userID: userID) { fetchedUser in
                DispatchQueue.main.async {
                    if let user = fetchedUser {
                        userData = fetchedUser
                        fireStoreService.user = user
                        self.checkIfFollowed(user: user)
                        self.fetchPostsfromProfile(postIDs: user.postIDArray)
                    } else {
                        print("Error: fetchedUser is nil")
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {

                Button {
                } label: {
                    if userID == fromUserID {
                        NavigationLink {
                            EditingProfileView(userData: $userData)
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(.white)
                                .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        Menu {
                            Button(action: {
                                showBlockAlert = true
                                firestoreService.addBlockUserData(to: userID)
                                alertView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                                alertView.titleLabel?.textColor = .white                                
                            }) { Label("Block", systemImage: "shield")
                                .alert(isPresent: $showBlockAlert, view: alertView)}
                            Button(action: {
                                showReportAlert = true
                                firestoreService.addReportUserData(to: userID)
                                reportView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                                reportView.titleLabel?.textColor = .white
                                print("Report")
                            }) { Label("Report", systemImage: "exclamationmark.bubble")
                                .alert(isPresent: $showReportAlert, view: reportView)}
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .bold))
                                .padding(10) // Reduced padding
                                .background(Circle().fill(Color.gray.opacity(0.6)))
                                .foregroundColor(.white)
                                .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                }
            }
        }
    }

    func fetchPostsfromProfile(postIDs: [String]) {
        let validPostIDs = postIDs.filter { !$0.isEmpty }
        guard !validPostIDs.isEmpty else {
            print("No valid post IDs to fetch.")
            return
        }
        let postsRef = db.collection("posts").whereField(FieldPath.documentID(), in: validPostIDs)
        postsRef.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot {
                firestoreService.posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
            } else if let error = error {
                print("Error fetching posts: \(error)")
            }
        }
    }

    func toggleFollow(user: User) {
        if isFollowed {
            firestoreService.removeUserFromFollowingArray(userID: userID)
            firestoreService.removeFollowNotification(user: user)
        } else {
            firestoreService.addUserToFollowingArray(userID: userID)
            firestoreService.addFollowNotification(user: user)
        }
        isFollowed.toggle()
    }

    func checkIfFollowed(user: User) {
        guard let fromUserID = fromUserID else { return }
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
    @State var fetchedCard: Card? = nil
    @State private var isStarred: Bool = false
    @State private var isCommentViewPresented: Bool = false
    @State private var userAvatarURL: String = ""
    var body: some View {
        GeometryReader { geometry in
            LazyVStack(alignment: .leading, spacing: 40) {
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
                            if let fetchedCard = fetchedCard {
                                PostButtonsView(card: fetchedCard, path: $path)
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
                            .foregroundColor(isStarred ? .cyan  : .white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: {
                        loadUserAvatar()
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
                Text(post.text)
                    .font(.title)
                    .padding()
            }

            .background(Color.black)
            .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
            .onAppear {
                fireStoreService.fetchUserData(userID: fromUserID ?? "")
                checkIfStarred()
                fireStoreService.fetchCardsFromProfile(for: post.cardID ?? "") { card in

                    guard let card = card else {return}
                    self.fetchedCard = card
                }
            }
        }
    }
    private func toggleLike() {
        if isStarred {
            removeUserFromLikerArray()
        } else {
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
        guard let fromUserID = fromUserID else {return}
        if post.likerIDArray.contains(fromUserID) {
            isStarred = true
        } else {
            isStarred = false
        }
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
    struct PostButtonsView: View {
        let card: Card
        @Binding var path: [ProfileDestination]

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
        @Binding var path: [ProfileDestination]
        @State private var userName: String = ""
        let db = Firestore.firestore()
        var body: some View {
            HStack {
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

    }
}
