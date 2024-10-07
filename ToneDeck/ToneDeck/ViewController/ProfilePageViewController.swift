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
                                            .frame(width: isFollowed ?  80 : 50)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(isFollowed ? .gray : .blue)
                                } else {
                                    EmptyView()  // Return an EmptyView if no user is available
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
                    // Action for settings
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
                            }) { Label("Block", systemImage: "pencil")
                                .alert(isPresent: $showBlockAlert, view: alertView)}
                            Button(action: {
                                showReportAlert = true
                                firestoreService.addReportUserData(to: userID)
                                reportView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                                reportView.titleLabel?.textColor = .white
                                print("Report")
                            }) { Label("Delete", systemImage: "trash")
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
    // case editingProfile(Void)
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
        LazyVStack(alignment: .leading, spacing: 40) {
            // Display Post Image
            KFImage(URL(string: post.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 600)
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
                    Image(systemName: isStarred ?"aqi.medium" :"aqi.medium" )
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(isStarred ? .cyan  : .white) // Change color based on state
                        .clipShape(Circle())
                        .symbolEffect(.variableColor.cumulative.dimInactiveLayers.reversing, options: .nonRepeating)
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
                .font(.body)
                .padding([.horizontal])
            PostInfoView(post: post, path: $path)
                .padding([.top, .leading, .trailing])
        }
        .padding([])
        .background(Color.black)
        .frame(maxWidth: .infinity, maxHeight: 800)
        .onAppear {
            fireStoreService.fetchUserData(userID: fromUserID ?? "")
            checkIfStarred()
            fireStoreService.fetchCardsFromProfile(for: post.cardID ?? "") { card in

                guard let card = card else {return}
                self.fetchedCard = card
            }
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
        @Binding var path: [ProfileDestination]

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
                        .font(.title3)
                       
                        .cornerRadius(10)
                        .foregroundColor(.white)

                }
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
            }
            .padding()
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
                        .padding([.leading, .trailing, .bottom])
                    Spacer()
                    Text("\(formattedDate(from: post.createdTime))")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding([.leading, .trailing, .bottom])
                }
                .buttonStyle(PlainButtonStyle())
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

    }
}


