//
//  FireStoreCardManager.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/12.
//

import Firebase

class FirestoreService: ObservableObject {
    @Published var cards: [Card] = []
    
    func fetchCards() {
        let db = Firestore.firestore()
        db.collection("cards").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching cards: \(error)")
            } else {
                if let snapshot = snapshot {
                    self.cards = snapshot.documents.compactMap { document -> Card? in
                        let data = document.data()
                        guard let cardName = data["cardName"] as? String,
                              let imageURL = data["imageURL"] as? String else {
                            return nil
                        }
                        return Card(id: document.documentID, cardName: cardName, imageURL: imageURL)
                    }
                }
            }
        }
    }
}

