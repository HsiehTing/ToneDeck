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
import AlertKit

enum CardDestination: Hashable {
    case camera(filterData: [Float?])
    case applyCard(card: Card)
    case addCard
}

struct CardViewController: View {
    @StateObject private var firestoreService = FirestoreService()
    @State var path: [CardDestination] = []
    @State private var isSearchActive = false
    @State var textFieldText : String = ""
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "PlayfairDisplayRoman-Bold", size: 52)!]
    }
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack{
                    List {
                        ForEach(firestoreService.cards.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  })) { card in
                            CardRow(card: card, path: $path)
                                .padding(.vertical, 10)
                                .clipped()
                        }
                    }
                    .onAppear {
                        firestoreService.fetchCards()
                    }
                    .listStyle(PlainListStyle())
                    .frame(maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.horizontal)
                    .navigationTitle(Text("Cards"))
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if isSearchActive {
                                // Show TextField when search is active
                                TextField("Search...", text: $textFieldText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 270)
                                    .padding(.leading, 10)

                                Button {
                                    path.append(.addCard)
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.white)
                                }
                                .padding(.leading, 10)
                            } else {
                                // Show "+" button when search is not active
                                Button {
                                    path.append(.addCard)
                                } label: {
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                }
                            }

                            // Magnifying glass button (toggle search mode)
                            Button {
                                withAnimation {
                                    isSearchActive.toggle() // Toggle search bar visibility
                                    if !isSearchActive {
                                        textFieldText = "" // Clear the search text when closing the search
                                    }
                                }
                            } label: {
                                Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
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
    //    init() {
    //        for fontFamily in UIFont.familyNames {
    //            print(fontFamily)
    //            for fontFamily in UIFont.fontNames(forFamilyName: fontFamily) {
    //                print("------ \(fontFamily)")
    //            }
    //        }
    //    }

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
                .cornerRadius(20)
                .clipped()
                .onTapGesture {
                    path.append(.applyCard(card: card))
                }
            // Text overlay
            Text(card.cardName)
                .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
                .fontWeight(.bold)
                .padding(8)
                .foregroundColor(.white)
            // Buttons overlay
            VStack {
                HStack {
                    Spacer()
                    OptionMenuButton(card: card)
                        .padding(.top, 20)

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
                            .font(.system(size: 12, weight: .bold))
                            .padding()
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                            .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 20)

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
    let alertView = AlertAppleMusic17View(title: "Copy to ClipBoard", subtitle: nil, icon: .done)
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
                alertView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                alertView.titleLabel?.textColor = .white

                print("Share tapped")
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .alert(isPresent: $showShareAlert, view: alertView)

            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .padding()
                .background(Color.gray.opacity(0.6))
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
#Preview {
    CardViewController()
}
