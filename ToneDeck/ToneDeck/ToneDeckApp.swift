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
                    let defaults = UserDefaults.standard
                   defaults.set("pb2odgkt1PB1lSgb2IY7", forKey: "userDocumentID")
                    //pb2odgkt1PB1lSgb2IY7//
                    //Ci792SJSsPqYhKczHOHL//
                    //defaults.removeObject(forKey: "userDocumentID")

                    checkUserData()
                })
        }
      }
    }
}
