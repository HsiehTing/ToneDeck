//
//  ContentView.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import SwiftUI

struct AfterSignInContentView: View {
    
    let firestoreService = FirestoreService()
    var body: some View {
        TabView {
            // First Tab
            VStack {
                NavigationView {
                            CardViewController()

                }
            }
            .padding()
            .tabItem {
                Label("", systemImage: "square.stack")
            }
            // Second Tab
            VStack {
                NavigationView {
                    NotificationPageView()
                }
            }
            .tabItem {
                Label("", systemImage: "bell")
            }
            // Third Tab
            VStack {
                NavigationView {
                    FeedView()
                }
            }
            .tabItem {
                Label("", systemImage: "square.text.square")
            }
            // Fourth Tab
            VStack {
                NavigationView {
                    ProfilePageView(userID: UserDefaults.standard.string(forKey: "userDocumentID") ?? "")
                }
            }
            .tabItem {
                Label("", systemImage: "person.crop.circle")
            }            
        }
        .tint(.gray)
    }


}

#Preview {
    ContentView()
}
