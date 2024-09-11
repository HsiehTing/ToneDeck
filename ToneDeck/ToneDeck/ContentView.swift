//
//  ContentView.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // First Tab
          
            VStack {
                NavigationView {
                    CardViewController()
                }
            }
            .tabItem {
                Label("", systemImage: "square.stack")
            }
            
            // Second Tab
            VStack {

            }
            .tabItem {
                Label("", systemImage: "bell")
            }
            
            // Third Tab
            VStack {
               
            }
            .tabItem {
                Label("", systemImage: "square.text.square")
            }
            
            // Fourth Tab
            VStack {
                Image(systemName: "person")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Profile")
            }
            .tabItem {
                Label("", systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    ContentView()
}
