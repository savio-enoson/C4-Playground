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
    
    let profileRadius = 80.0
    
    var body: some View {
        HStack(spacing: 0) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: profileRadius, height: profileRadius)
                .background(.primary)
            
            VStack {
                // Player name box
                Text(playerName)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)  // Make it take all available width
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                    .background(.black)
                
                Spacer()
                
                // Icon bar
                HStack(spacing: 12) {
                    Text("🛜")
                    
                    Text("💀")
                    
                    Spacer()
                }
                .padding(.leading, 12)

                Spacer()
            }
            .frame(minHeight: profileRadius, maxHeight: .infinity)
            .background(.gray)
        }
        .frame(width: 3 * profileRadius, height: profileRadius)
    }
}

struct PlayerProfile_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlayerProfile(
                playerName: "John Doe",
                image: Image("test_sav"),
                color: .blue
            )
            .previewDisplayName("Default Profile")
            
            PlayerProfile(
                playerName: "Jane Smith",
                image: Image(systemName: "person.crop.circle.fill"),
                color: .green
            )
            .previewDisplayName("Alternative Profile")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
