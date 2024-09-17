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
    var createdTime: Date
    var photoIDArray: [String]
    var cardID: String?
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
                            PostView(post: post, card: card, path: $path)  // Pass path to child views
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
    @Binding var path: [FeedDestination]

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
        .overlay(OverlayButtons())
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

struct OverlayButtons: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Button(action: {
                    // Action for star button
                }) {
                    Image(systemName: "star")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(4)

                Button(action: {
                    // Action for bubble button
                }) {
                    Image(systemName: "bubble.right")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(4)
            }
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding([.leading, .trailing])
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
