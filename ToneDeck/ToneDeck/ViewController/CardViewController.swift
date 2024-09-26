//
//  CardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

enum CardDestination: Hashable {
    case camera(filterData: [Float?])
    case applyCard(card: Card)
    case addCard
}

struct CardViewController: View {
    @StateObject private var firestoreService = FirestoreService()
    @State var path: [CardDestination] = []
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                List {
                    ForEach(firestoreService.cards.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  })) { card in
                        CardRow(card: card, path: $path)
                            .padding(.vertical, 10)
                    }
                }
                .onAppear {
                    firestoreService.fetchCards()
                }
                .navigationTitle("Cards")
            }
            .navigationBarItems(trailing: Button(action: {
                // Add action for the "+" button here
                path.append(.addCard)
            }) {
                Image(systemName: "plus")
            })
            .navigationDestination(for: CardDestination.self) { destination in
                switch destination {
                case .camera(let filterData):
                    CameraView(filterData: filterData, path: $path)
                case .applyCard(let card):
                    ApplyCardViewControllerWrapper(card: card)

                case .addCard:
                    AddCardViewController(path: $path)
                }
        }
        }
    }
}
struct CardRow: View {
    let card: Card
    @Binding var path: [CardDestination]
    var body: some View {

            ZStack(alignment: .bottomLeading) {
                // Load image using Kingfisher, and make it tappable to trigger push navigation
                KFImage(URL(string: card.avatar))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .clipped()
                    .onTapGesture {

                        path.append(.applyCard(card: card))
                    }
                // Text overlay
                Text(card.cardName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                // Buttons overlay
                VStack {
                    HStack {
                        Spacer()
                        OptionMenuButton(card: card)
                            .padding(.top, 10)
                            .padding(.trailing, 10)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        
                        // Directly including the Camera Button in bottom-right
                        Button(action: {
                            // Push CameraView onto the navigation stack
                            path.append(.camera(filterData: card.filterData))
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .bold))
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 10)
                        .padding(.trailing, 10)
                    }
                }
            }
            .cornerRadius(10)
            .clipped()
            // Handle programmatic navigation based on path
    }
}
struct OptionMenuButton: View {
    @State private var showRenameAlert = false
    @State private var showShareAlert = false
    @State private var newName = ""
    let db = Firestore.firestore()
    let card: Card
    var body: some View {
        Menu {
            Button(action: {
                // 顯示改名彈出框
                showRenameAlert = true
            }) {
                Label("Rename", systemImage: "pencil")
            }
            Button(action: {
                // 添加刪除操作
                print("Delete tapped")
                deleteCard()
            }) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: {
                // 添加分享操作
                showShareAlert = true
                UIPasteboard.general.string = card.id
                
                print("Share tapped")
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .alert("Copy to ClipBoard", isPresented: $showShareAlert) {

                    } message: {
                        Text("")
                    }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .foregroundColor(.white)
                .buttonStyle(PlainButtonStyle())
        }
        .alert("Rename Card", isPresented: $showRenameAlert) {
            TextField("Enter new name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                renameCard()
            }
        } message: {
            Text("Please enter a new name for the card.")
        }
    }
    private func renameCard() {
        let cardID = card.id
        db.collection("cards").document(cardID).updateData([
            "cardName": newName
        ]) { error in
            if let error = error {
                print("Error updating card name: \(error)")
            } else {
                print("Card name successfully updated")
            }
        }
    }
    private func deleteCard() {
        let cardID = card.id
        db.collection("cards").document(cardID).delete()
    }
}

