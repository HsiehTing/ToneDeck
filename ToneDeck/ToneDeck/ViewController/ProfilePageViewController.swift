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
    let userID: String
    let defaultAvatarURL = "https://example.com/default_avatar.png"  // Set a default image
    let db = Firestore.firestore()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Info Section
                if let user = firestoreService.user {
                    VStack(spacing: 8) {
                        // User Avatar
                        KFImage(URL(string: user.avatar))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .shadow(radius: 10)

                        // User Name
                        Text(user.userName)
                            .font(.title)
                            .fontWeight(.bold)

                        // Following and Followers Count
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
                            Button (action:{
                                toggleFollow()
                            }) {
                                Text(isFollowed ?"follow" : "unfollow")
                            }
                        }
                    }
                }

                // Post Grid Section
                if !firestoreService.posts.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(firestoreService.posts) { post in
                            KFImage(URL(string: post.imageURL))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(8)
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
        .onAppear {
            firestoreService.fetchUserData(userID: userID ?? "")  // Fetch user data when the view appears
        }
    }
    private func toggleFollow() {

        if isFollowed {
            // If already starred, remove the user's ID from the likerIDArray
            addUserToFollowingArray()
        } else {
            // If not starred, add the user's ID to the likerIDArray
            removeUserFromFollowingArray()
        }
        isFollowed.toggle()
    }
    private func removeUserFromFollowingArray() {

        let followRef = Firestore.firestore().collection("followRequests").whereField("from", isEqualTo: fromUserID).whereField("to", isEqualTo: userID)
        followRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
                    for document in documents {
                        document.reference.delete()
                    }
        }

        let followerRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        let followingRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: fromUserID)
        followerRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followerArray": FieldValue.arrayRemove([fromUserID])])
            }
        }
        followingRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followingArray": FieldValue.arrayRemove([userID])])
            }
        }

    }
    private func addUserToFollowingArray() {

        let followRequestData: [String: Any] = [
                    "from": fromUserID,
                    "to": userID,
                    "createdTime": Timestamp(),
                    "status": "pending"
                ]
        db.collection("followRequests").addDocument(data: followRequestData) { error in
            if let error = error {
                print("Error sending follow request: \(error.localizedDescription)")
            } else {
                print("Follow request sent successfully.")
            }
        }
        let followerRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        let followingRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: fromUserID)
        followerRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followerArray": FieldValue.arrayUnion([fromUserID])])
            }
        }
        followingRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followingArray": FieldValue.arrayUnion([userID])])
            }
        }
    }
}
