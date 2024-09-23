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

struct CardViewController: View {
    @State private var path = [String]()
    @StateObject private var firestoreService = FirestoreService()
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                List {
                    ForEach(firestoreService.cards) { card in
                        CardRow(card: card)
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
                path.append("add card")
            }) {
                Image(systemName: "plus")
            })
            .navigationDestination(for: String.self) { value in
                if value == "add card" {
                    AddCardViewController(path: $path)
                }
            }
        }
    }
}
struct CardRow: View {
    let card: Card

    var body: some View {
        ZStack {
            // Background image
              NavigationLink(destination: ApplyCardViewControllerWrapper(card: card)) {
                KFImage(URL(string: card.avatar))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)  // Set the desired frame size
                    .cornerRadius(10)
                    .clipped()
                        // Overlay for buttons
                        VStack {
                            HStack {
                                Spacer()
                                OptionMenuButton(card: card)  // Option button at top right
                                    .padding(.top, 10)
                                    .padding(.trailing, 10)
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                CameraButton(card: card)  // Camera button at bottom right
                                    .padding(.bottom, 10)
                                    .padding(.trailing, 10)
                            }
                        }
                    }
            }
            .cornerRadius(10)
            .clipped()
        }
    }


struct OptionMenuButton: View {
    @State private var showRenameAlert = false
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
                print("Share tapped")
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .foregroundColor(.white)
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
struct CameraButton: View {
    let card: Card
    @State private var filterData: [Float] = []

    var body: some View {
        NavigationLink(destination: CameraView(filterData: card.filterData)) {
            Button(action: {
                print("Camera tapped")
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20, weight: .bold))
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            // Initialize filterData once the view appears
            filterData = card.filterData
        }
    }
}

