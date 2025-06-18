//
//  ContentView.swift
//  C4 Playground
//
//  Created by Savio Enoson on 09/06/25.
//
import GameKit
import Foundation
import SwiftUI

//  SUMMARY FOR GAVIN AND KARYNA
//  It goes like this:
//  ContentView -> Triggers authenticatePlayer -> Set game center viewController (brings up the login prompt) -> Sets the GKLocalPlayer.local variable to your apple account. After authenticating, NOTHING happens until you press the Start button and call startMatchmaking.
//  TODO: Double click the authenticatePlayer function and jump to definition.

//  Additional info: Data is sent and received in the form of Data objects, which are encoded and decoded. Check CardGame+MatchData file if you need to add more types of pings / requests. It roughly goes as follows:
//  Something calls match.sendData (built in method from GK) and sends an encoded data object
//  Set up a case in MatchDelegate's receiveData function to handle the incoming data.


struct ContentView: View {
    @StateObject var game = CardGame()
    
    var body: some View {
        MainMenuView(game: game)
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
