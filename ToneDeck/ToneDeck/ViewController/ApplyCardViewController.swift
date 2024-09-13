//
//  ApplyCardViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/12.
//

import Foundation
import SwiftUI


struct ApplyCardViewController: View {
    let card: Card // Receive the card data passed from CardViewController
    
    var body: some View {
        VStack {
            Text("Card Name: \(card.cardName)")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding()
            
            // Add more UI elements or actions based on the card data
        }
        .navigationTitle("Apply Card")
    }
}
