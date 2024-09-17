//
//  ToneDeckApp.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import SwiftUI

@main
struct ToneDeckApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
      WindowGroup {
        NavigationView {
          ContentView()
                .onAppear(perform: {
                    checkUserData()
                })
        }
      }
    }
}
