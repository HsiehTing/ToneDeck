//
//  ToneDeckTests.swift
//  ToneDeckTests
//
//  Created by 謝霆 on 2024/10/22.
//

import XCTest
import Firebase
@testable import ToneDeck


 class ToneDeckTests: XCTestCase {
     var viewModel: NotificationViewModel!
     let mockUserName = "user"
     let timeStamp = Date()
     let avatar =
     "https://firebasestorage.googleapis.com:443/v0/b/tonedecksting.appspot.com/o/photo%2F48608521-EBA3-489B-8783-BE6E08617D3C.jpg?alt=media&token=d6c10183-e94b-4749-92da-2f48963cce71"
     let postIDArray = [""]
     let followingIDArray = [""]
     let followerIDArray = [""]
     let photoIDArray = [""]
     var db: Firestore!
     override func setUpWithError() throws {
         // Put setup code here. This method is called before the invocation of each test method in the class.
         super.setUp()
                 viewModel = NotificationViewModel()

     }

     override func setUp() {
         super.setUp()
         let settings = FirestoreSettings()
         settings.host =  "localhost:8080"
         settings.isPersistenceEnabled = false
         settings.isSSLEnabled = false
         Firestore.firestore().settings = settings
         db = Firestore.firestore()
     }

     override func tearDown() {
        db = nil
         super.tearDown()
     }

     override func tearDownWithError() throws {
         // Put teardown code here. This method is called after the invocation of each test method in the class.
         viewModel = nil
                 super.tearDown()
     }

     func testAddDocument() {
         let expectation = self.expectation(description: "Document Added")

         let testData = ["name": "Test", "age": 24] as [String : Any]

         db.collection("usersUnitTest").addDocument(data: testData) { error in
             XCTAssertNil(error, "Error should be nil")
             expectation.fulfill()
         }

         waitForExpectations(timeout: 5)
     }

     func testFetchDocuments() {
         let expectation = self.expectation(description: "Document Fetched")
         db.collection("usersUnitTest").getDocuments { snapShot, error in
             XCTAssertNil(error, "Error should be nil")
             XCTAssertNotNil(snapShot, "Snapshot should not be nil")
             expectation.fulfill()
         }
     }

     func testToggleFollowBehavior() throws {
             XCTAssertFalse(viewModel.isFollowed, "isFollowed should initially be false")

             viewModel.testToggleFollow()
             XCTAssertTrue(viewModel.isFollowed, "isFollowed should be true after first toggle")

             viewModel.testToggleFollow()
             XCTAssertFalse(viewModel.isFollowed, "isFollowed should be false after second toggle")
         }

     func testToggleFollowBehaviorTrue() throws {
         viewModel = NotificationViewModel(isFollowed: true)
         XCTAssertTrue(viewModel.isFollowed, "isFollowed should be true after first toggle")

         viewModel.testToggleFollow()
         XCTAssertFalse(viewModel.isFollowed, "isFollowed should be false after second toggle")

         viewModel.testToggleFollow()
         XCTAssertTrue(viewModel.isFollowed, "isFollowed should be true after first toggle")
     }

     func testButtonLabel() {
         // Mock user data
         let mockUser = User(id: "", userName: mockUserName, avatar: avatar, postIDArray: postIDArray, followingArray: followingIDArray,
                             followerArray: followerIDArray, blockUserArray: [""], photoIDArray: photoIDArray)

         let initialButtonText = viewModel.isFollowed ? "follow" : "unfollow"
         XCTAssertEqual(initialButtonText, "unfollow", "The initial button text should be 'unfollow' when isFollowed is false")

         viewModel.toggleFollow(user: mockUser)
         let toggledButtonText = viewModel.isFollowed ? "follow" : "unfollow"
         XCTAssertEqual(toggledButtonText, "follow", "The button text should be 'follow' when isFollowed is true")
     }

}
