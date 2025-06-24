//
//  CardGameRevised.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 23/06/25.
//

import Foundation
import GameKit

class CardGameState {
    var players: [Player] = []
    var localPlayerIndex: Int = 0
    var currentTurnIndex: Int = 0
    var localPlayer: GKPlayer
    
//    Game related
    var tally: Int = 0
    var maxTally: Int = 21
    var discardPile: [Card] = []

    init(){
        self.localPlayer = GKLocalPlayer.local
    }
    
    var currentPlayer: Player {
        players[currentTurnIndex]
    }

    func isMyTurn() -> Bool {
        return localPlayerIndex == currentTurnIndex
    }
    
    func playCard(player: Player, card: Card){
        // Safely remove the card from the player's hand
        guard let cardIndex = player.hand.firstIndex(of: card) else {
            print("⚠️ Card not found in player's hand.")
            return
        }
        // Apply card effects
        switch card.cardType {
        case .number:
            if let value = Int(card.value.rawValue) {
                tally += value
                if tally > maxTally {
                    player.busted()
                }
            } else {
                print("⚠️ Invalid numeric value: \(card.value.rawValue)")
            }

        case .action:
            // TODO: Add support for action cards here
            print("🃏 Action cards not yet implemented.")
            break
        }

        // Move the card to the discard pile
        let discarded = player.hand.remove(at: cardIndex)
        discardPile.append(discarded)
    }
}
