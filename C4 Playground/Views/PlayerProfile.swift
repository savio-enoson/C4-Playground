//
//  PlayerProfile.swift
//  C4 Playground
//
//  Created by Savio Enoson on 13/06/25.
//

import Foundation
import SwiftUI


struct PlayerProfile: View {
    let playerName: String
    let image: Image
    let color: Color
    
    let profileRadius = 30.0
    
    var body: some View {
        HStack(spacing: 8) {
            // Circular profile picture
            image
                .resizable()
                .scaledToFit()
                .frame(width: profileRadius, height: profileRadius)
                .padding()
                .clipShape(Circle())
                .shadow(radius: 5)
            
            VStack {
                // Player name box
                Text(playerName)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                
                // Icon bar
                HStack(spacing: 16) {
                    
                }
                .padding(.top, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary)
                        .shadow(radius: 2)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 2)
        )
    }
}
