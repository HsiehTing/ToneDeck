//
//  NotificationCenterViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/21.
//

import SwiftUI
import Kingfisher

struct Notification: Identifiable {
    var id: String
    var fromUserPhoto: String
    var fromUserName: String
    var postImage: String
    var notificationType: NotificationType
}

enum NotificationType {
    case like
    case comment
    case useCard
    case follow
}
struct NotificationsView: View {
    let notifications: [Notification] = [
        Notification(id: "1", fromUserPhoto: "https://example.com/photo1.png", fromUserName: "User1", postImage: "https://example.com/post1.png", notificationType: .like),
        Notification(id: "2", fromUserPhoto: "https://example.com/photo2.png", fromUserName: "User2", postImage: "https://example.com/post2.png", notificationType: .useCard),
        Notification(id: "3", fromUserPhoto: "https://example.com/photo3.png", fromUserName: "User3", postImage: "https://example.com/post3.png", notificationType: .comment),
        Notification(id: "4", fromUserPhoto: "https://example.com/photo4.png", fromUserName: "User4", postImage: "https://example.com/post3.png", notificationType: .follow)
    ]

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
    let notification: Notification

    var body: some View {
        HStack(spacing: 16) {
            // 發送者的頭像
            KFImage(URL(string: notification.fromUserPhoto))
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // 動態顯示根據通知類型的訊息
                if notification.notificationType == .like {
                    Text("\(notification.fromUserName) just liked your post")
                        .font(.subheadline)
                        .fontWeight(.bold)
                } else if notification.notificationType == .comment {
                    Text("\(notification.fromUserName) commented on your post")
                        .font(.subheadline)
                        .fontWeight(.bold)
                } else if notification.notificationType == .useCard {
                    Text("\(notification.fromUserName) used your card")
                        .font(.subheadline)
                        .fontWeight(.bold)
                } else if notification.notificationType == .follow {
                    Text("\(notification.fromUserName) started following you")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    // Follow back button for follow notifications
                    Button(action: {
                        // Handle follow back action
                    }) {
                        Text("Follow Back")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            Spacer()

            // 顯示 postImage（如果有的話）
//            if let postImageURL = notification.postImage {
//                KFImage(URL(string: postImageURL))
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 50, height: 50)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//            }
        }
        .padding(.vertical, 8)
    }
}

