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
    @Published var photos: [Photo] = []
    @Published var posts: [Post] = []
    @Published var users: [User] = []
    @Published var user: User? = nil
    let db = Firestore.firestore()

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
            guard let document = snapshot, document.exists, let data = document.data() else {
                print("No card found for ID: \(cardID)")
                completion()
                return
            }
            // Extract cardName and imageURL directly from the document data
            let cardName = data["cardName"] as? String ?? "Unknown Card"
            let imageURL = data["imageURL"] as? String ?? ""
            // Create a simple Card struct or dictionary to store these two fields
            let card = Card(id: cardID, cardName: cardName, imageURL: imageURL)
            // Store the card in the dictionary
            DispatchQueue.main.async {
                self.cardsDict[cardID] = card
                completion()
            }
        }
    }

    func fetchCards() {
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
    func fetchUserData(userID: String) {
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    self.user = try document.data(as: User.self)
                    self.fetchPosts(postIDs: self.user?.postIDArray ?? [])
                } catch {
                    print("Error decoding user: \(error)")
                }
            } else {
                print("User does not exist")
            }
        }
    }

    // Fetch posts based on postIDArray
    func fetchPosts(postIDs: [String]) {
        // Filter out any empty or invalid document IDs
        let validPostIDs = postIDs.filter { !$0.isEmpty }
        
        guard !validPostIDs.isEmpty else {
            print("No valid post IDs to fetch.")
            return
        }
        
        let postsRef = db.collection("posts").whereField(FieldPath.documentID(), in: validPostIDs)
        postsRef.getDocuments { snapshot, error in
            if let snapshot = snapshot {
                self.posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
            } else if let error = error {
                print("Error fetching posts: \(error)")
            }
        }
    }

    func fetchPhotos() {
        let db = Firestore.firestore()
        db.collection("photos").getDocuments { snapshot, error in
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

}

func checkUserData() {
    let mockUserName = "Sting"
    let userName = mockUserName
    let timeStamp = Date()
    let avatar = ""
    let postIDArray = [""]
    let followingIDArray = [""]
    let followerIDArray = [""]
    let photoIDArray = [""]
    // 檢查 user defaults 中是否有儲存 document ID
    let defaults = UserDefaults.standard
    if let savedUserID = defaults.string(forKey: "userDocumentID") {
        // 如果有，檢查 Firestore 中是否有該使用者的資料
        Firestore.firestore().collection("users").document(savedUserID).getDocument { (document, error) in
            if let document = document, document.exists {
                // 使用者資料已存在，略過儲存
                print("User already exists. Skipping save.")
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
        "id": document.documentID,
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
struct CardDetail: Identifiable, Decodable {
    var id: String
    var cardName: String
    var imageURL: String
    var createdTime: Timestamp
    var filterData: [String]
    var userID: String
}

struct Card: Identifiable, Decodable, Hashable, Equatable {
    var id: String
    var cardName: String
    var imageURL: String
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
