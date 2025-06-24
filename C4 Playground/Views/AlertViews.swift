//
//  AlertGameEnd.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 24/06/25.
//

import SwiftUI

struct BustedAlertView: View {
    let playerName: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack{
            Text("💥\(playerName)💥\nhas gone over the limit!\nBetter luck next time!")
                .font(.cBody)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .offset(x: 0, y: 40)
        }
        .frame(height: 250)
        .background(
            Image("alert_busted")
                .resizable()
                .scaledToFill()
        )
        .shadow(radius: 20)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: UUID())
    }
}

struct WinnerAlertView: View{
    let playerName: String
    var onDismiss: () -> Void

    var body: some View {
        ZStack{
            Text("🏆 WINNER 🏆\nCongrats\n\(playerName)\nfor being the last one to bust!")
                .font(.cBody)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .offset(x: 0, y: 35)
        }
        .frame(height: 250)
        .background(
            Image("alert_winner")
                .resizable()
                .scaledToFill()
        )
        .shadow(radius: 20)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: UUID())
    }
}

#Preview {
    BustedAlertView(playerName: "Gay") {
        
    }
    
    WinnerAlertView(playerName: "Straight"){
        
    }
}
