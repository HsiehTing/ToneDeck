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
    let fireStoreService = FirestoreService()
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
                            if userID != fromUserID {
                                Button (action:{
                                    toggleFollow(user: user)
                                }) {
                                    Text(isFollowed ?"follow" : "unfollow")
                                }
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
            guard let user = firestoreService.user else {return}
            checkIfFollowed(user: user)
        }
    }
    private func toggleFollow(user: User) {


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
    private func checkIfFollowed(user: User) {
        // Assume we get the likerIDArray from the post
        guard let fromUserID = fromUserID else {return}
        if user.followerArray.contains(fromUserID) {
            isFollowed = true
        } else {
            isFollowed = false
        }
    }

}
