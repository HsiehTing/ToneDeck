//
//  Initial Page View.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/10/14.
//

import SwiftUI
struct InitialView: View {

    @Binding var isLoading: Bool
    @Binding var animate: Bool
       var body: some View {
           GeometryReader { geometry in
               ZStack {
                   Color.black.edgesIgnoringSafeArea(.all)

                   ForEach(0..<3) { index in
                       RoundedRectangle(cornerRadius: 15)
                           .fill(Color.white.opacity(1 - Double(index) * 0.2))
                           .frame(width: 200, height: 150)
                           .offset(x: self.xOffset(for: index, in: geometry.size, animated: animate),
                                   y: self.yOffset(for: index, in: geometry.size, animated: animate))
                           .opacity(animate ? 1.0 : 0.0)
                           .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(Double(index) * 0.2), value: animate)
                   }
               }
           }
       }

    func xOffset(for index: Int, in size: CGSize, animated: Bool) -> CGFloat {
            let finalOffset: CGFloat = CGFloat(index - 1) * 20
            return animated ? finalOffset : 0
        }

        func yOffset(for index: Int, in size: CGSize, animated: Bool) -> CGFloat {
            let finalOffset: CGFloat = CGFloat(index - 1) * -12
            return animated ? finalOffset : size.height * 0.75
        }
   }
func xOffset(for index: Int, in size: CGSize, animated: Bool) -> CGFloat {
    let finalOffset: CGFloat = CGFloat(index - 1) * 20
    switch index {
    case 0: return animated ? finalOffset : -size.width
    case 1: return animated ? finalOffset : size.width
    case 2: return animated ? finalOffset : 0
    default: return 0
    }
}

func yOffset(for index: Int, in size: CGSize, animated: Bool) -> CGFloat {
    let finalOffset: CGFloat = CGFloat(index - 1) * -20
    switch index {
    case 0: return animated ? finalOffset : -size.height
    case 1: return animated ? finalOffset : -size.height
    case 2: return animated ? finalOffset : size.height
    default: return 0
    }
}
