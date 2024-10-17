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
    @State var isLoading = true
    @StateObject private var firestoreService = FirestoreService()
    @State var path: [CardDestination] = []
    @State private var isSearchActive = false
    @State var textFieldText : String = ""
    @State private var showingImageSourceAlert = false
    @State var animate = false
    @State private var loadingOpacity = 1.0
    @State private var mainContentOpacity = 0.0
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "PlayfairDisplayRoman-Bold", size: 52)!]
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                InitialView(isLoading: $isLoading, animate: $animate)
                                   .opacity(loadingOpacity)
                VStack{
                    if firestoreService.cards.count == 0 {
                        Text("Add Card to Card List")
                            .font(.custom("PlayfairDisplayRoman-Semibold", size: 24))
                            .foregroundStyle(Color.gray)
                    } else{
                        List {
                            ForEach(firestoreService.cards.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  })) { card in
                                CardRow(card: card, path: $path)
                                    .clipped()
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .transition(.slide)
                                    .animation(.easeInOut)
                            }
                        }
                        
                        .listStyle(PlainListStyle())
                    }
                }
                .opacity(mainContentOpacity)
                .onAppear {
                    animate = false
                    animateLoading()  // 開始執行無限重複動畫
                    firestoreService.fetchCardsCompletion { success in
                        if success {

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 1.3)) {

                                    loadingOpacity = 0
                                    mainContentOpacity = 1
                                    animate = false
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .edgesIgnoringSafeArea(.horizontal)
                .navigationTitle(Text("Cards"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if isSearchActive {
                                // Show TextField when search is active
                                TextField("Search by Card ID", text: $textFieldText)
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
                                    isSearchActive.toggle()
                                    if !isSearchActive {
                                        textFieldText = ""
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
                        ApplyCardView(card: card)
                    case .addCard:
                        AddCardViewController(path: $path)
                    case .searchCard(card: let card):
                        ApplyCardView(card: card)
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
    func animateLoading() {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
}


struct CardRow: View {
    let card: Card
    @Binding var path: [CardDestination]
    @State private var isAnimationTriggered: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Image
                KFImage(URL(string: card.imageURL))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(20)
                    .clipped()
                    .onTapGesture {
                        path.append(.applyCard(card: card))
                    }

                // Overlay elements
                VStack {
                    HStack {
                        Spacer()
                        OptionMenuButton(card: card)
                            .padding(.top, 10)
                            .padding(.trailing, 10)
                    }
                    Spacer()
                    HStack {
                        // Card name
                        Text(card.cardName)
                            .font(.custom("PlayfairDisplayRoman-Semibold", size: min(52, geometry.size.width * 0.06)))
                            .fontWeight(.bold)
                            .padding(8)
                            .foregroundColor(.white)

                        Spacer()

                        // Camera button
                        Button(action: {
                            path.append(.camera(filterData: card.filterData))
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: min(18, geometry.size.width * 0.05), weight: .bold))
                                .padding(8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 10)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offsetAnimation(isTriggered: isAnimationTriggered, delay: 0.3)
            .cornerRadius(10)
            .clipped()
        }
        .aspectRatio(370/200, contentMode: .fit)
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
    let alertcopyView = AlertAppleMusic17View(title: "Copy to ClipBoard", subtitle: nil, icon: .done)
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
                alertcopyView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 21)
                alertcopyView.titleLabel?.textColor = .white
                
                print("Share tapped")
            }) { Label("Share", systemImage: "square.and.arrow.up")
                    .alert(isPresent: $showShareAlert, view: alertcopyView)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .bold))
                .padding(10) // Reduced padding
                .background(Circle().fill(Color.white.opacity(0.2)))
                .foregroundColor(.white)
                .buttonStyle(PlainButtonStyle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 10)
       
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

