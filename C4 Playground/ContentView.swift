//
//  ContentView.swift
//  C4 Playground
//
//  Created by Savio Enoson on 09/06/25.
//
import GameKit
import Foundation
import SwiftUI


struct ContentView: View {
    @StateObject var game = CardGame()
    
    var body: some View {
        VStack {
            Text("This is the Home Screen")
                .font(.largeTitle)
            
            Button {
                game.startMatchmaking()
            } label: {
                Text("Start Machmaking")
                    .font(.largeTitle)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(radius: 2)
                    )
            }
        }
        .onAppear {
            if !game.inGame {
                game.authenticatePlayer()
            }
        }
        .fullScreenCover(isPresented: $game.inGame) {
            GameView(game: game)
        }
    }
}

#Preview {
    ContentView()
}
