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
        VStack(spacing: 20) {
            Text("💥 BUSTED 💥")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.top)

            Text("\(playerName) has gone over the limit!")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button(action: onDismiss) {
                Text("OK")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(minWidth: 80)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(red: 0.941, green: 0.298, blue: 0.247))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white, lineWidth: 4)
                )
        )
        .padding(30)
        .shadow(radius: 20)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: UUID()) // For smooth transitions
    }
}
#Preview {
    BustedAlertView(playerName: "Gay") {
        // Just for preview – nothing needed here
    }
}
