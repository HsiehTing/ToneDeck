//
//  NotificationCenterViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/21.
//

import SwiftUI
import Kingfisher
import Firebase

enum NotificationType: String, Codable {
    case like = "like"
    case comment = "comment"
    case useCard = "useCard"
    case follow = "follow"
}
class NotificationViewModel: ObservableObject {
    @StateObject private var firestoreService = FirestoreService()
    @Published var notifications: [Notification] = []
    @Published var isFollowed :Bool
    init(isFollowed: Bool = false) {
        self.isFollowed = isFollowed
    }
    @Published var user: User?
    func fetchNotification () {
        firestoreService.fetchNotifications { [weak self] result in
            switch result {
            case .success(let notifications):
                DispatchQueue.main.async {
                    self?.notifications = notifications
                }
            case .failure(let error):
                print("Error fetching notifications: \(error)")
            }
        }

    }
    func testToggleFollow() {
        self.isFollowed.toggle()
    }
    func fetchNotifications() {
            firestoreService.fetchNotifications { [weak self] result in
                switch result {
                case .success(let notifications):
                    DispatchQueue.main.async {
                        self?.notifications = notifications
                    }
                case .failure(let error):
                    print("Error fetching notifications: \(error)")
                }
            }
        }
    func toggleFollow(user: User) {
        let firestoreService = FirestoreService()
        if self.isFollowed {
            firestoreService.addUserToFollowingArray(userID: user.id)
            firestoreService.addFollowNotification(user: user)
        } else {
            firestoreService.removeUserFromFollowingArray(userID: user.id)
            firestoreService.removeFollowNotification(user: user)
        }
        self.isFollowed.toggle()
    }
    func getNotificationText(notification: Notification) -> String {
        guard let userName = user?.userName else {
                return "Unknown user"
            }

            switch notification.type {
            case .like:
                return "\(userName) just liked your post"
            case .comment:
                return "\(userName) commented on your post"
            case .useCard:
                return "\(userName) used your card"
            case .follow:
                return "\(userName) started following you"
            }
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

struct NotificationPageView: View {
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var viewModel = NotificationViewModel()
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.notifications.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  })) { notification in
                    NotificationRow(notification: notification)
                        .padding(.horizontal)
                }
            }
            .onAppear {
                viewModel.fetchNotification()
            }
        }
        .navigationTitle("Notifications")
    }
}

struct NotificationRow: View {
    @StateObject private var viewModel = NotificationViewModel()
    let notification: Notification
    @State var isFollowed: Bool = false
    var body: some View {
        HStack(spacing: 16) {
            KFImage(URL(string: notification.fromUserPhoto))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.getNotificationText(notification: notification))
                    .font(.body)
                    .fontWeight(.medium)
                    if notification.type == .like || notification.type == .useCard || notification.type == .comment {
                    KFImage(URL(string: notification.postImage))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if notification.type == .follow {
                    Button(action: {
                        guard let user = viewModel.user else {return}
                        viewModel.toggleFollow(user: user)
                    }) {
                        Text(viewModel.isFollowed ?"follow" : "unfollow")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Spacer()
        }
        .onAppear {
            viewModel.fetchUser(fromUserID: notification.from)
        }
    }
}
