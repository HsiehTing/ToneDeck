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
                }                .onAppear {
                    firestoreService.fetchCards()
                }
                .navigationTitle("Cards")
            }
            //.navigationTitle("Cards")
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


struct Card: Identifiable {
    var id: String
    var cardName: String
    var imageURL: String
}

struct CardRow: View {
    let card: Card
    @State private var showApplyCardView = false
    
    var body: some View {
        NavigationLink(destination: ApplyCardViewControllerWrapper(card: card)){
            ZStack(alignment: .bottomLeading) {
                // Load image using Kingfisher (or any other way you prefer)
                KFImage(URL(string: card.imageURL))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .clipped()
                   // .contentShape(Rectangle())
                    .overlay(
                                        NavigationLink(destination: ApplyCardViewControllerWrapper(card: card)) {
                                            Color.clear // 透明的可點擊區域
                                        }
                                        .contentShape(Rectangle()) // 使得整個區域可點擊
                                    )
                Text(card.cardName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                // Option button (right top)
                HStack {
                    Spacer()
                    VStack {
                        OptionMenuButton(card: card)
                        Spacer()
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                
                // Camera button (right bottom)
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        CameraButton()
                    }
                }
                .padding(.bottom, 10)
                .padding(.trailing, 10)
            }
            .cornerRadius(10)
            .clipped()

        }
    }
}

struct OptionMenuButton: View {
    let card: Card
    var body: some View {
        Menu {
            Button(action: {
                // Add action for renaming
                print("Rename tapped")
            }) {
                Label("Rename", systemImage: "pencil")
            }
            Button(action: {
                // Add action for deleting
                print("Delete tapped")
            }) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: {
                // Add action for sharing
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
    }
}

struct CameraButton: View {
    var body: some View {
        Button(action: {
            // Add action for camera button
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
}
