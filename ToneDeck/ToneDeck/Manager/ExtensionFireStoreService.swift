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
        userRef.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {return}
            for document in  documents {
                document.reference.updateData(["avatar": newAvatarURL])
            }
        }

    }
    func updateUserName (userID: String, newName: String) {
        let userRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        userRef.getDocuments { querySnapshot, error in
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
            ]){ error in
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
            ]){ error in
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
    let mockUserName = "default user name"
    let userName = mockUserName
    let timeStamp = Date()
    let avatar = 
    "https://firebasestorage.googleapis.com:443/v0/b/tonedecksting.appspot.com/o/photo%2F48608521-EBA3-489B-8783-BE6E08617D3C.jpg?alt=media&token=d6c10183-e94b-4749-92da-2f48963cce71"
    let postIDArray = [""]
    let followingIDArray = [""]
    let followerIDArray = [""]
    let photoIDArray = [""]
    // 檢查 user defaults 中是否有儲存 document ID
    let defaults = UserDefaults.standard
    if let savedUserID = defaults.string(forKey: "userDocumentID") {
        // 如果有，檢查 Firestore 中是否有該使用者的資料
        Firestore.firestore().collection("users").whereField("id", isEqualTo: savedUserID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            if let snapshot = snapshot, !snapshot.isEmpty {
                        print("ID already exists. No need to add.")
                    } else {
                // 使用者資料不存在，新增資料
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
        // 沒有儲存的 document ID，直接新增資料
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
    let userData: [String: Any] = [
        "id": UserDefaults.standard.string(forKey: "userDocumentID"),
        "userName": userName,
        "avatar": avatar,
        "postIDArray": postIDArray,
        "followingArray": followingIDArray,
        "followerArray": followerIDArray,
        "photoIDArray": photoIDArray,
        "createdTime": timeStamp
    ]

    document.setData(userData) { error in
        if let error = error {
            print("Error saving card: \(error)")
        } else {
            print("User successfully saved!")
            // 儲存 document ID 到 UserDefaults
            let defaults = UserDefaults.standard
            defaults.set(document.documentID, forKey: "userDocumentID")
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
}

struct User: Identifiable, Codable {
    var id: String
    var userName: String
    var avatar: String
    var postIDArray: [String]
    var followingArray: [String]
    var followerArray: [String]
    //var photoIDArray: [String]
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
