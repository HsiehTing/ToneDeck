//
//  FireStoreCardManager.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/12.
//

import Firebase

class FirestoreService: ObservableObject {
    @Published var cards: [Card] = []
    @Published var cardsDetail: [CardDetail] = []
    @Published var cardsDict: [String: Card] = [:]
    @Published var cardData: Card?
    @Published var photos: [Photo] = []
    @Published var posts: [Post] = []
    @Published var users: [User] = []
    @Published var notifications: [Notification] = []
    @Published var collections: [CardCollection] = []
    @Published var user: User? = nil
    let db = Firestore.firestore()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    
     func fetchPosts() {
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No posts found.")
                return
            }
            // Clear current posts and cards before fetching new data
            self.posts.removeAll()
            // Fetch card details based on cardID in posts
            let group = DispatchGroup()
            for document in documents {
                do {
                    // Try to decode each document into a Post object
                    let post = try document.data(as: Post.self)
                    // Append the post to the posts array
                    self.posts.append(post)
                    // If the post has a cardID, fetch the card details
                    if let cardID = post.cardID {
                        group.enter()
                        self.fetchCardDetails(for: cardID) {
                            group.leave()
                        }
                    }
                } catch {
                    // Handle any errors during decoding
                    print("Error decoding post: \(error.localizedDescription)")
                }
            }

            group.notify(queue: .main) {
                print("Finished fetching all card details.")
                print(self.cards)
                print(self.posts)
            }
        }
    }
    
    func fetchCardDetails(for cardID: String, completion: @escaping () -> Void) {
        let cardRef = db.collection("cards").document(cardID)
        cardRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching cards: \(error.localizedDescription)")
                return
            }
            guard let document = snapshot, document.exists, let data = document.data() else {
                print("No card found for ID: \(cardID)")
                completion()
                return
            }
            let cardName = data["cardName"] as? String ?? "Unknown Card"
            let imageURL = data["imageURL"] as? String ?? ""
            let createdTIme = data["createdTime"] as? Timestamp ?? Timestamp()
            let userID = data["creatorID"] as? String ?? ""
            let filterData = data["filterData"] as? [Float] ?? [0]
            if let dominantColorData = data["dominantColor"] as? [String: Any],
               let red = dominantColorData["red"] as? Double,
               let green = dominantColorData["green"] as? Double,
               let blue = dominantColorData["blue"] as? Double,
               let alpha = dominantColorData["alpha"] as? Double {

                let dominantColor = DominantColor(red: red, green: green, blue: blue, alpha: alpha)

                let card = Card(id: cardID, cardName: cardName, imageURL: imageURL, createdTime: createdTIme, filterData: filterData, creatorID: userID, dominantColor: dominantColor)
                DispatchQueue.main.async {
                   self.cardsDict[cardID] = card
                   completion()
               }
            } else {
                // Handle case where dominantColor data is missing or not in the expected format
                let card = Card(id: cardID, cardName: cardName, imageURL: imageURL, createdTime: createdTIme, filterData: filterData, creatorID: userID,
                dominantColor: DominantColor(red: 0, green: 0, blue: 0, alpha: 1))
                DispatchQueue.main.async {
                   self.cardsDict[cardID] = card
                   completion()
               }
            }
        }
    }

    func fetchCards() {
        db.collection("cards").whereField("creatorID", isEqualTo: fromUserID).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching cards: \(error)")
            } else {
                if let snapshot = snapshot {
                    self.cards = snapshot.documents.compactMap { document -> Card? in
                        let data = document.data()
                        let cardID = data["id"] as? String ?? "Unknown Card"
                        let cardName = data["cardName"] as? String ?? "Unknown Card"
                        let imageURL = data["imageURL"] as? String ?? ""
                        let createdTIme = data["createdTime"] as? Timestamp ?? Timestamp()
                        let userID = data["creatorID"] as? String ?? ""
                        let filterData = data["filterData"] as? [Float] ?? [0]
                        let dominantColor = data["dominantColor"] as?  DominantColor
                        if let dominantColorData = data["dominantColor"] as? [String: Any],
                           let red = dominantColorData["red"] as? Double,
                           let green = dominantColorData["green"] as? Double,
                           let blue = dominantColorData["blue"] as? Double,
                           let alpha = dominantColorData["alpha"] as? Double {

                            let dominantColor = DominantColor(red: red, green: green, blue: blue, alpha: alpha)

                            return Card(id: cardID, cardName: cardName, imageURL: imageURL, createdTime: createdTIme, filterData: filterData, creatorID: userID, dominantColor: dominantColor)
                        } else {
                            // Handle case where dominantColor data is missing or not in the expected format
                            return Card(id: cardID, cardName: cardName, imageURL: imageURL, createdTime: createdTIme,
                                filterData: filterData, creatorID: userID, dominantColor: DominantColor(red: 0, green: 0, blue: 0, alpha: 1))
                        }

                    }
                }
            }
        }
    }
    func fetchCardsFromProfile(for cardID: String, completion: @escaping (Card?) -> Void) {
            db.collection("cards")
                .whereField("id", isEqualTo: cardID)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching cards: \(error.localizedDescription)")
                        completion(nil)
                    } else if let document = snapshot?.documents.first {
                        let fetchedCards = try? document.data(as: Card.self)

                        DispatchQueue.main.async {
                            self.cardData = fetchedCards
                            completion(fetchedCards)
                        }
                    }
                }
        }
    func fetchCardFromCardID(cardID: String) {
        db.collection("cards")
            .whereField("cardID", isEqualTo: cardID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching card: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    if let document = snapshot.documents.first, // Assuming you want the first document
                       let card = try? document.data(as: Card.self) { // Cast to your `Card` model
                        DispatchQueue.main.async {
                            self.cardData = card
                        }
                    }
                }
            }
    }
    func fetchUserData(userID: String) {
        db.collection("users").whereField("id", isEqualTo: userID).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
            } else if let snapshot = snapshot {
                do {
                    if let document = snapshot.documents.first,
                       let user = try? document.data(as: User.self) {
                        self.user = user
                    }
                } catch {
                    print("Error decoding user: \(error)")
                }
            } else {
                print("User does not exist")
            }
        }
    }
    func fetchProfile(userID: String, completion: @escaping (User?) -> Void) {
            db.collection("users").whereField("id", isEqualTo: userID).addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    completion(nil)
                } else if let snapshot = snapshot {
                    do {
                        if let document = snapshot.documents.first,
                           let user = try? document.data(as: User.self) {
                            self.user = user
                            completion(user)
                        } else {
                            completion(nil)
                        }
                    } catch {
                        print("Error decoding user: \(error)")
                        completion(nil)
                    }
                } else {
                    print("User does not exist")
                    completion(nil)
            }
        }
    }

    func fetchNotifications() {
            db.collection("notifications").whereField("to", isEqualTo: fromUserID).addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    return
                }

                guard let documents = querySnapshot?.documents else { return }
                self.notifications = documents.compactMap { document -> Notification? in
                    do {
                        let notification = try document.data(as: Notification.self)
                        return notification
                    } catch {
                        print("Error decoding notification: \(error)")
                        return nil
                    }
                }
            }
        }
//    func fetchUserName(for userID: String) {
//            let userRef = db.collection("users").whereField("id", isEqualTo: userID)
//            userRef.getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error fetching user: \(error)")
//                } else if let snapshot = snapshot, let document = snapshot.documents.first {
//                    if let user = try? document.data(as: User.self) {
//                        userName = user.userName  // 更新用户名
//                    }
//                }
//            }
//        }
    func fetchPostsfromProfile(postIDs: [String]) {
        let validPostIDs = postIDs.filter { !$0.isEmpty }
        guard !validPostIDs.isEmpty else {
            print("No valid post IDs to fetch.")
            return
        }
        let postsRef = db.collection("posts").whereField(FieldPath.documentID(), in: validPostIDs)
        postsRef.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot {
                self.posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
            } else if let error = error {
                print("Error fetching posts: \(error)")
            }
        }
    }
    func fetchPhotos() {
        let db = Firestore.firestore()
        let defaults = UserDefaults.standard
        let userID = defaults.string(forKey: "userDocumentID")
        db.collection("photos").whereField("creatorID", isEqualTo: userID).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching photos: \(error)")
                return
            }
            if let documents = snapshot?.documents {
                self.photos = documents.compactMap { doc in
                    let data = doc.data()
                    // Ensure all necessary fields are present and properly casted
                    guard let cardID = data["cardID"] as? String,
                          let creatorID = data["creatorID"] as? String,
                          let createdTime = data["createdTime"] as? Timestamp ,
                          let imageURL = data["imageURL"] as? String else {
                        // Return nil if any field is missing or of incorrect type
                          return Photo(id: "", imageURL: "", cardID: "", creatorID: "", createdTime: Timestamp())
                    }
                    // Return a valid Photo object if all fields are correct
                    print("Fetched document with ID: \(doc.documentID)") // Print document ID to debug
                    return Photo(id: doc.documentID, imageURL: imageURL, cardID: cardID, creatorID: creatorID, createdTime: createdTime)
                }
            }
        }
    }
    func removeUserFromFollowingArray(userID: String) {

        let followRef = Firestore.firestore().collection("followRequests").whereField("from", isEqualTo: fromUserID).whereField("to", isEqualTo: userID)
        followRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
                    for document in documents {
                        document.reference.delete()
                    }
        }
        let followerRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        let followingRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: fromUserID)
        followerRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followerArray": FieldValue.arrayRemove([self.fromUserID ?? ""])])
            }
        }
        followingRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followingArray": FieldValue.arrayRemove([userID])])
            }
        }

    }
    func addUserToFollowingArray(userID: String) {

        let followRequestData: [String: Any] = [
                    "from": fromUserID,
                    "to": userID,
                    "createdTime": Timestamp(),
                    "status": "pending"
                ]
        db.collection("followRequests").addDocument(data: followRequestData) { error in
            if let error = error {
                print("Error sending follow request: \(error.localizedDescription)")
            } else {
                print("Follow request sent successfully.")
            }
        }
        let followerRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        let followingRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: fromUserID)
        followerRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followerArray": FieldValue.arrayUnion([self.fromUserID])])
            }
        }
        followingRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["followingArray": FieldValue.arrayUnion([userID])])
            }
        }
    }
     func addFollowNotification(user: User) {
        let notifications = Firestore.firestore().collection("notifications")
        let document = notifications.document()
        let data: [String: Any] = [
             "id": document.documentID,
             "fromUserPhoto": user.avatar,
             "from": fromUserID ?? "",
             "to": user.id,
             "postImage": user.avatar,
             "type":  NotificationType.follow.rawValue,
             "createdTime": Timestamp()
        ]
        document.setData(data)
    }
    func removeFollowNotification(user: User) {
            guard let fromUserID = fromUserID else { return }
            let notificationsRef = Firestore.firestore().collection("notifications")
            let query = notificationsRef
                .whereField("from", isEqualTo: fromUserID)
                .whereField("to", isEqualTo: user.id)
                .whereField("type", isEqualTo: NotificationType.follow.rawValue)

            query.getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    for document in querySnapshot!.documents {
                        document.reference.delete { err in
                            if let err = err {
                                print("Error removing document: \(err)")
                            } else {
                                print("Document successfully removed!")
                            }
                        }
                    }
                }
            }
        }
     func deleteCard(card: Card) {
        let cardID = card.id
        db.collection("cards").document(cardID).delete() { error in
            if let error = error {
                print("Error deleting card: \(error.localizedDescription)")
            } else {
                if let index = self.cards.firstIndex(where: { $0.id == cardID }) {
                    self.cards.remove(at: index) // 更新本地数据源
                }
            }
        }
    }
}

