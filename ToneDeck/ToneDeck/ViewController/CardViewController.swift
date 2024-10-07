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
    case camera(filterData: [Float])
    case applyCard(card: Card)
    case searchCard(card: Card)
    case addCard
}

struct CardViewController: View {
    @StateObject private var firestoreService = FirestoreService()
    @State var path: [CardDestination] = []
    @State private var isSearchActive = false
    @State var textFieldText : String = ""
    @State private var showingImageSourceAlert = false

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
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .transition(.slide)
                                .animation(.easeInOut)
                        }
                    }

                    .listStyle(PlainListStyle())
                    .onAppear {
                        firestoreService.fetchCards()
                    }
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
                                    let db = Firestore.firestore()
                                    db.collection("cards")
                                        .whereField("id", isEqualTo: textFieldText)
                                        .getDocuments { snapshot, error in
                                            if let error = error {
                                                print("Error fetching card: \(error.localizedDescription)")
                                            } else if let snapshot = snapshot, let document = snapshot.documents.first {
                                                if let card = try? document.data(as: Card.self) {
                                                    DispatchQueue.main.async {
                                                        path.append(CardDestination.searchCard(card: card))
                                                    }
                                                } else {
                                                    print("Failed to parse card data")
                                                }
                                            } else {
                                                print("No card found with the provided cardID")
                                            }
                                        }
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
                                        .foregroundColor(.cyan)
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
                    case .searchCard(card: let card):
                        ApplyCardViewControllerWrapper(card: card)
                    }
                }
            }
        }
        .background(
            Color.black
                        .onTapGesture {
                            UIApplication.shared.endEditing()
                        }
                )
    }
}
struct CardRow: View {
    let card: Card
    @Binding var path: [CardDestination]
    @State private var isAnimationTriggered: Bool = false
    var body: some View {

        ZStack(alignment: .bottomLeading) {
            // Load image using Kingfisher, and make it tappable to trigger push navigation
            KFImage(URL(string: card.imageURL))
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 200)
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
                    }) { Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .bold))
                            .padding(10)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                            .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 10)
                    .padding(.trailing, 10)
                }
            }
        }
        .offsetAnimation(isTriggered: isAnimationTriggered, delay: 0.9)
        .cornerRadius(10)
        .clipped()
        .onAppear {
            isAnimationTriggered = true
        }
        .onDisappear {
            isAnimationTriggered = false
        }
    }

}
struct OptionMenuButton: View {
    @State private var showRenameAlert = false
    @State private var showShareAlert = false
    @State private var newName = ""
    let alertView = AlertAppleMusic17View(title: "Copy to ClipBoard", subtitle: nil, icon: .done)
    let db = Firestore.firestore()
    let firestoreService = FirestoreService()
    let card: Card
    var body: some View {
        Menu { Button(action: {
            // 顯示改名彈出框
            showRenameAlert = true
        }) { Label("Rename", systemImage: "pencil")
        }
            Button(action: {
                // 添加刪除操作
                print("Delete tapped")
                firestoreService.deleteCard(card: card)
            }) { Label("Delete", systemImage: "trash")}
            Button(action: {
                // 添加分享操作
                showShareAlert = true
                UIPasteboard.general.string = card.id
                alertView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                alertView.titleLabel?.textColor = .white

                print("Share tapped")
            }) { Label("Share", systemImage: "square.and.arrow.up")
                    .alert(isPresent: $showShareAlert, view: alertView)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .bold))
                .padding(10) // Reduced padding
                .background(Circle().fill(Color.gray.opacity(0.6)))
                .foregroundColor(.white)
                .buttonStyle(PlainButtonStyle())
        }
        .buttonStyle(PlainButtonStyle())
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
}
#Preview {
    CardViewController()
}
extension View {

    func offsetAnimation(isTriggered: Bool, delay: CGFloat) -> some View {
        return self
            .offset(y: isTriggered ? 0 : 30)
            .opacity(isTriggered ? 1 : 0)
            .animation(.smooth(duration: 1.4, extraBounce: 0.2).delay(delay), value: isTriggered)
    }

    func bannerAnimation(isTriggered: Bool) -> some View {
        return self
            .scaleEffect(isTriggered ? 1 : 0.95)
            .opacity(isTriggered ? 1 : 0)
            .animation(.easeOut(duration: 1), value: isTriggered)
    }

}

