//
//  ExtensionFireStoreService.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/30.
//

import Firebase
extension FirestoreService {
    func fetchCollections() {
        let db = Firestore.firestore()
        db.collection("collections").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching collections: \(error.localizedDescription)")
                return
            }

            self.collections = snapshot?.documents.compactMap { document -> CardCollection? in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let cardIds = data["cardIds"] as? [String] else {
                    return nil
                }

                let cards = self.cards.filter { cardIds.contains($0.id) }
                return CardCollection(id: document.documentID, name: name, cards: cards)
            } ?? []
        }
    }
    func fetchCardsCompletion(completion: @escaping (Bool) -> Void) {
        db.collection("cards").whereField("creatorID", isEqualTo: fromUserID).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching cards: \(error)")
                completion(false)
            } else {
                if let snapshot = snapshot {
                    self.cards = snapshot.documents.compactMap { document -> Card? in
                        let data = document.data()
                        let cardID = data["id"] as? String ?? "Unknown Card"
                        let cardName = data["cardName"] as? String ?? "Unknown Card"
                        let imageURL = data["imageURL"] as? String ?? ""
                        let createdTime = data["createdTime"] as? Timestamp ?? Timestamp()
                        let userID = data["creatorID"] as? String ?? ""
                        let filterData = data["filterData"] as? [Float] ?? [0]
                        if let dominantColorData = data["dominantColor"] as? [String: Any],
                           let red = dominantColorData["red"] as? Double,
                           let green = dominantColorData["green"] as? Double,
                           let blue = dominantColorData["blue"] as? Double,
                           let alpha = dominantColorData["alpha"] as? Double {

                            let dominantColor = DominantColor(red: red, green: green, blue: blue, alpha: alpha)
                            return Card(id: cardID, cardName: cardName, imageURL: imageURL, createdTime: createdTime, filterData: filterData, creatorID: userID, dominantColor: dominantColor)
                        } else {
                            return Card(id: cardID, cardName: cardName, imageURL: imageURL, createdTime: createdTime,
                                        filterData: filterData, creatorID: userID, dominantColor: DominantColor(red: 0, green: 0, blue: 0, alpha: 1))
                        }
                    }
                    completion(true) // 資料成功獲取後呼叫 completion
                } else {
                    completion(false) // 若無 snapshot，則通知失敗
                }
            }
        }
    }

    func createCollection(name: String, cardIds: [String]) {
        let db = Firestore.firestore()
        let collectionData: [String: Any] = [
            "name": name,
            "cardIds": cardIds
        ]

        db.collection("collections").addDocument(data: collectionData) { error in
            if let error = error {
                print("Error creating collection: \(error.localizedDescription)")
            } else {
                self.fetchCollections()
            }
        }
    }
    func updateUserAvatar (userID: String, newAvatarURL: String) {
        let userRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        userRef.getDocuments { querySnapshot, _ in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["avatar": newAvatarURL])
            }
        }

    }
    func updateUserStatus (status: Bool) {
        let userRef = Firestore.firestore().collection("posts").whereField("creatorID", isEqualTo: fromUserID)
        userRef.getDocuments { querySnapshot, _ in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["isPrivate": status])
            }
        }

    }
    func updateDeleteStatus (status: Bool) {
        let userRef = Firestore.firestore().collection("posts").whereField("creatorID", isEqualTo: fromUserID)
        userRef.getDocuments { querySnapshot, _ in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["isDelete": status])
            }
        }

    }
    func updateUserName (userID: String, newName: String) {
        let userRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        userRef.getDocuments { querySnapshot, _ in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["userName": newName])
            }
        }
    }
    func addBlockUserData(to targetID: String) {
        guard let fromUserID = fromUserID else { return }
        let userRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: fromUserID)
        userRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents, let document = documents.first else {return}
            let documentRef = document.reference
            documentRef.setData([
                "blockUserArray": FieldValue.arrayUnion([targetID])
            ]) { error in
                if let error = error {
                    print("Error updating blockUserArray: \(error.localizedDescription)")
                } else {
                    print("Successfully added targetID to blockUserArray")
                }
            }
        }
    }
    func addReportUserData(to targetID: String) {
        guard let fromUserID = fromUserID else { return }
        let userRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: fromUserID)
        userRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents, let document = documents.first else {return}
            let documentRef = document.reference
            documentRef.setData([
                "reportUserArray": FieldValue.arrayUnion([targetID])
            ]) { error in
                if let error = error {
                    print("Error updating blockUserArray: \(error.localizedDescription)")
                } else {
                    print("Successfully added targetID to reportUserArray")
                }
            }
        }
    }

}
func checkUserData() {
    let mockUserName = "user"
    let userName = mockUserName
    let timeStamp = Date()
    let avatar =
    "https://firebasestorage.googleapis.com:443/v0/b/tonedecksting.appspot.com/o/photo%2F48608521-EBA3-489B-8783-BE6E08617D3C.jpg?alt=media&token=d6c10183-e94b-4749-92da-2f48963cce71"
    let postIDArray = [""]
    let followingIDArray = [""]
    let followerIDArray = [""]
    let photoIDArray = [""]

    let defaults = UserDefaults.standard
    if let savedUserID = defaults.string(forKey: "userDocumentID") {

        Firestore.firestore().collection("users").whereField("id", isEqualTo: savedUserID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            if let snapshot = snapshot, !snapshot.isEmpty {
                        print("ID already exists. No need to add.")
                    } else {

                saveNewUser(userName: userName,
                            avatar: avatar,
                            postIDArray: postIDArray,
                            followingIDArray: followingIDArray,
                            followerIDArray: followerIDArray,
                            photoIDArray: photoIDArray,
                            timeStamp: timeStamp)
            }
        }
    } else {

        saveNewUser(userName: userName,
                    avatar: avatar,
                    postIDArray: postIDArray,
                    followingIDArray: followingIDArray,
                    followerIDArray: followerIDArray,
                    photoIDArray: photoIDArray,
                    timeStamp: timeStamp)
    }

}

func saveNewUser(userName: String, avatar: String, postIDArray: [String], followingIDArray: [String], followerIDArray: [String], photoIDArray: [String], timeStamp: Date) {
    let db = Firestore.firestore()
    let users = db.collection("users")
    let document = users.document() // 自動生成 document ID
    let defaults = UserDefaults.standard
    if  defaults.bool(forKey: "signinWithApple") == false {
        defaults.set(document.documentID, forKey: "userDocumentID")
    }
    let userData: [String: Any] = [
        "id": UserDefaults.standard.string(forKey: "userDocumentID"),

        "userName": userName,
        "avatar": avatar,
        "postIDArray": postIDArray,
        "followingArray": followingIDArray,
        "followerArray": followerIDArray,
        "photoIDArray": photoIDArray,
        "blockUserArray": [],
        "createdTime": timeStamp,
        "isPrivate": false
    ]

    document.setData(userData) { error in
        if let error = error {
            print("Error saving card: \(error)")
        } else {
            print("User successfully saved!")

            let defaults = UserDefaults.standard

            defaults.set(false, forKey: "privacyStatus")
        }
    }

}
struct CardCollection: Identifiable {
    let id: String
    let name: String
    let cards: [Card]
}
struct CardDetail: Identifiable, Decodable {
    var id: String
    var cardName: String
    var imageURL: String
    var createdTime: Timestamp
    var filterData: [Float]
    var userID: String
}

struct Card: Identifiable, Decodable, Hashable, Equatable {
    var id: String
    var cardName: String
    var imageURL: String
    var createdTime: Timestamp
    var filterData: [Float]
    var creatorID: String
    var dominantColor: DominantColor
}
struct DominantColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}

struct User: Identifiable, Codable {
    var id: String
    var userName: String
    var avatar: String
    var postIDArray: [String]
    var followingArray: [String]
    var followerArray: [String]
    var blockUserArray: [String]
    var photoIDArray: [String]
}

struct Photo: Identifiable, Decodable {
    var id: String
    var imageURL: String
    var cardID: String
    var creatorID: String
    var createdTime: Timestamp
}

struct Notification: Identifiable, Decodable {
    var id: String
    var fromUserPhoto: String
    var from: String
    var postImage: String
    var to: String
    var type: NotificationType
    var createdTime: Timestamp
}
