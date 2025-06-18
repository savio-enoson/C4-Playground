//
//  CardGame+GKMatchDelegate.swift
//  C4 Playground
//
//  Created by Savio Enoson on 13/06/25.
//

import SwiftUI
import Foundation
import GameKit

extension CardGame: GKMatchDelegate {
    /// Handles a connected, disconnected, or unknown player state.
    /// - Tag:didChange
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            print("\(player.displayName) Connected")
            
        case .disconnected:
            print("\(player.displayName) Disconnected")
            
        default:
            break
        }
    }
    
    /// Reinvites a player when they disconnect from the match.
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        print("Reinviting disconnected player")

        return false
    }
    
    /// Handles receiving a message from another player.
    /// - Tag:didReceiveData
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
//        print("local player \(localPlayer.displayName) receiving data:")
        // Decode the data representation of the game data.
        let gameData = decode(matchData: data)
//        
//        //      Event handlers
//        //      Playing a card
        if let playedCard = gameData?.playedCard {
//            print("\(player.displayName) is playing a card.")
            guard let playerIndex = gameData?.playerIndex else { return }
            guard let indexInHand = gameData?.indexInHand else { return }
            
            // Play card from other player's hand
            playCard(playedCard: playedCard, indexInHand: indexInHand, targetPlayerIndex: gameData?.targetPlayerIndex, isMyCard: false)
            
            // Find and remove the specific card from player's hand
            playerHands[playerIndex].remove(at: indexInHand)
        }
        //      Dealing cards
        else if let targetPlayerIndex = gameData?.targetPlayerIndex {
            guard let numOfCards = gameData?.numOfCards else { return }
//            print("dealing \(numOfCards) cards to player \(players[targetPlayerIndex].displayName)")
            for i in 0..<numOfCards {
                var card = deck.removeFirst()
                playerHands[targetPlayerIndex].append(card)
            }
            //            dealCards(to: targetPlayerIndex, numOfCards: numOfCards)
        }
        //      Reshuffling deck and discard
        else if let receivedCards = gameData?.listOfCards {
            guard let message = gameData?.message else { return }
            switch message {
            case "init":
//                print("player \(player.displayName) sent the shuffled deck")
                deck.removeAll()
                deck = receivedCards
            case "reshuffle":
                discardPile.removeFirst(reshuffleCount)
                deck.append(contentsOf: receivedCards)
            default:
                return
            }
        }
        else if let message = gameData?.message {
            switch message {
            case "eliminate":
                guard let playerIndex = gameData?.playerIndex else { return }
                eliminatePlayer(playerIndex: playerIndex)
            case "ready":
                if localPlayer == host {
//                    print("received ready message from \(player.displayName)")
                    playersReady += 1
                    if playersReady == players.count {
                        startGame()
                    }
                }
            case "begin":
                if localPlayer != host {
                    
                }
            default:
                return
            }
        }
    }
}
