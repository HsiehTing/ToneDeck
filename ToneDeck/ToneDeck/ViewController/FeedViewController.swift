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

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(firestoreService.posts) { post in
                        if let cardID = post.cardID,
                           let card = firestoreService.cardsDict[cardID] {
                            PostView(post: post, card: card, path: $path)// Pass path to child views
                        } else {
                            PostView(post: post, card: nil, path: $path)  // Handle missing card case
                        }
                    }
                }
                .navigationTitle("Feed")
                .onAppear {
                    firestoreService.fetchPosts()  // Load posts on view appear
                }
                .navigationBarItems(trailing: Button(action: {
                    path.append(.addPost)  // Navigate to the add post view
                    print("Navigating to addPost")  // Debugging print
                }) {
                    Image(systemName: "plus")
                })
                .navigationDestination(for: FeedDestination.self) { destination in
                    switch destination {
                    case .addPost:
                        PhotoGridView()  // Ensure PhotoGridView is initialized correctly
                    case .applyCard(let card):
                        ApplyCardViewControllerWrapper(card: card)
                    }
                }
            }
        }
    }
}
struct PostView: View {
    let post: Post
    let card: Card? // Optional card
    let userID: String = "HU31meYbVzbXDGKcqV8i"
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
                .frame(maxWidth: .infinity, maxHeight: 800)
                .clipped()

            // Display card buttons if the card exists
            if let card = card {
                PostButtonsView(card: card, path: $path)
                    .padding(.vertical, 4)
            } else {
                // Display loading placeholder if card is nil
                Text("Loading card...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
            }

            // Display Post Text
            Text(post.text)
                .font(.body)
                .padding([.top, .leading, .trailing])

            // Display Creator ID and Time
            PostInfoView(post: post)
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
                    CommentView(postID: post.id, userID: userID, userAvatarURL: userAvatarURL)
                }
            }
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding([.leading, .trailing])
    )
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
    private func checkIfStarred() {
           // Assume we get the likerIDArray from the post
        if post.likerIDArray.contains(userID) {
                   isStarred = true
               } else {
                   isStarred = false
               }
       }

       // Function to add the user to the likerIDArray in the posts collection
       private func addUserToLikerArray() {
           // Add your Firestore or database code here
           // Example: Firestore logic to update likerIDArray
           let postRef = Firestore.firestore().collection("posts").document(post.id)
           postRef.updateData([
               "likerIDArray": FieldValue.arrayUnion([userID])
           ]) { error in
               if let error = error {
                   print("Error adding user to likerIDArray: \(error)")
               } else {
                   print("User added to likerIDArray successfully.")
               }
           }
       }

       // Function to remove the user from the likerIDArray in the posts collection
       private func removeUserFromLikerArray() {
           // Firestore logic to update likerIDArray
           let postRef = Firestore.firestore().collection("posts").document(post.id)
           postRef.updateData([
               "likerIDArray": FieldValue.arrayRemove([userID])
           ]) { error in
               if let error = error {
                   print("Error removing user from likerIDArray: \(error)")
               } else {
                   print("User removed from likerIDArray successfully.")
               }
           }
       }
    private func loadUserAvatar() {
        let userRef = Firestore.firestore().collection("users").document(userID)
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
                path.append(.applyCard(card: card))  // Navigate to applyCard view
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
                KFImage(URL(string: card.imageURL))
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

    var body: some View {
        HStack {
            Text("by \(post.creatorID)")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Text("\(post.createdTime, formatter: postDateFormatter)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding([.leading, .trailing, .bottom])
    }
}

// Date Formatter for displaying time
private let postDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
