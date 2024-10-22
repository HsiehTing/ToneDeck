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
    @Published var isFollowed = false 
    @Published var user: User?
    func fetchNotification () {
        firestoreService.fetchNotifications()
    }
    func testToggleFollow() {
        self.isFollowed.toggle()
    }

    func toggleFollow(user: User) {
        let firestoreService = FirestoreService()
        if self.isFollowed {
            // If already starred, remove the user's ID from the likerIDArray
            firestoreService.addUserToFollowingArray(userID: user.id)
            firestoreService.addFollowNotification(user: user)
        } else {
            // If not starred, add the user's ID to the likerIDArray
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
        // 使用 snapshot listener 來監聽實時變化
        userRef.addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("User not found")
                return
            }
            // 獲取第一個文檔（假設 id 是唯一的）
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
                ForEach(firestoreService.notifications.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  })) { notification in
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
struct NotificationsView: View {
    let notifications: [Notification] = [ ]
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Notifications")
    }
}
struct NotificationRow: View {
    @StateObject private var viewModel = NotificationViewModel()
    let notification: Notification
//    @State private var user: User?
    @State var isFollowed: Bool = false
    var body: some View {
        HStack(spacing: 16) {
            // 顯示來自使用者的頭像
            KFImage(URL(string: notification.fromUserPhoto))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            // 通知的文字和圖片
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.getNotificationText(notification: notification))
                    .font(.body)
                    .fontWeight(.medium)
                
                // 如果通知包含圖片
                if notification.type == .like || notification.type == .useCard || notification.type == .comment {
                    KFImage(URL(string: notification.postImage))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if notification.type == .follow {
                    // 如果通知是 "follow"，顯示追蹤按鈕
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
            viewModel.fetchUser(fromUserID: notification.from)  // 根據 fromUserID 取得對應的 User
        }
    }

//    func getNotificationText(notification: Notification) -> String {
//        guard let userName = viewModel.user?.userName else {
//                return "Unknown user"
//            }
//
//            switch notification.type {
//            case .like:
//                return "\(userName) just liked your post"
//            case .comment:
//                return "\(userName) commented on your post"
//            case .useCard:
//                return "\(userName) used your card"
//            case .follow:
//                return "\(userName) started following you"
//            }
//    }
//    private func toggleFollow(user: User) {
//        let firestoreService = FirestoreService()
//        if isFollowed {
//            // If already starred, remove the user's ID from the likerIDArray
//            firestoreService.addUserToFollowingArray(userID: user.id)
//            firestoreService.addFollowNotification(user: user)
//        } else {
//            // If not starred, add the user's ID to the likerIDArray
//            firestoreService.removeUserFromFollowingArray(userID: user.id)
//            firestoreService.removeFollowNotification(user: user)
//        }
//        isFollowed.toggle()
//    }
//    func fetchUser(fromUserID: String) {
//        let db = Firestore.firestore()
//        let userRef = db.collection("users").whereField("id", isEqualTo: fromUserID)
//        // 使用 snapshot listener 來監聽實時變化
//        userRef.addSnapshotListener { querySnapshot, error in
//            if let error = error {
//                print("Error fetching user data: \(error)")
//                return
//            }
//            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
//                print("User not found")
//                return
//            }
//            // 獲取第一個文檔（假設 id 是唯一的）
//            let document = documents[0]
//            do {
//                self.user = try document.data(as: User.self)
//            } catch {
//                print("Error decoding user: \(error)")
//            }
//        }
//    }
}
