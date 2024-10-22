//
//  ToneDeckTests.swift
//  ToneDeckTests
//
//  Created by 謝霆 on 2024/10/22.
//

import XCTest
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
     override func setUpWithError() throws {
         // Put setup code here. This method is called before the invocation of each test method in the class.
         super.setUp()
                 viewModel = NotificationViewModel()
     }

     override func tearDownWithError() throws {
         // Put teardown code here. This method is called after the invocation of each test method in the class.
         viewModel = nil
                 super.tearDown()
     }

     func testToggleFollowBehavior() throws {
             // Initial state should be false
             XCTAssertFalse(viewModel.isFollowed, "isFollowed should initially be false")

             // First toggle - should become true
             viewModel.testToggleFollow()
             XCTAssertTrue(viewModel.isFollowed, "isFollowed should be true after first toggle")

             // Second toggle - should become false
             viewModel.testToggleFollow()
             XCTAssertFalse(viewModel.isFollowed, "isFollowed should be false after second toggle")
         }

     func testButtonLabel() {
         // Mock user data
         let mockUser = User(id: "", userName: mockUserName, avatar: avatar, postIDArray: postIDArray, followingArray: followingIDArray,
                             followerArray: followerIDArray, blockUserArray: [""], photoIDArray: photoIDArray)

         // Initially, isFollowed is false, so the button should display "unfollow"
         let initialButtonText = viewModel.isFollowed ? "follow" : "unfollow"
         XCTAssertEqual(initialButtonText, "unfollow", "The initial button text should be 'unfollow' when isFollowed is false")

         // Toggle follow, isFollowed becomes true, so the button should display "follow"
         viewModel.toggleFollow(user: mockUser)
         let toggledButtonText = viewModel.isFollowed ? "follow" : "unfollow"
         XCTAssertEqual(toggledButtonText, "follow", "The button text should be 'follow' when isFollowed is true")
     }

     

}
