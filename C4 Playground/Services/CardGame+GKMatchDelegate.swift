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
        return false
    }
    
    /// Handles receiving a message from another player.
    /// - Tag:didReceiveData
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        // Decode the data representation of the game data.
        let gameData = decode(matchData: data)
        
        //      Event handlers
        //      Playing a card
        if let playedCard = gameData?.playedCard {
            guard let playerIndex = gameData?.playerIndex else { return }
            
            // Find and remove the specific card from player's hand
            if let cardIndex = playerHands[playerIndex].firstIndex(where: { $0.id == playedCard.id }) {
                    playerHands[playerIndex].remove(at: cardIndex)
                    
                    if gameData?.targetPlayerIndex != nil {
                        // Action Cards
                        // TODO: Implement Action Card Behavior
                    } else {
                        // Number Cards
//                        print("player \(player.displayName) played a number card")
                        discardPile.append(playedCard)
                        tally += Int(playedCard.value.rawValue) ?? 0
                        whoseTurn = (whoseTurn + 1) % players.count
                    }
                }
            }
            //      Dealing cards
            else if let targetPlayerIndex = gameData?.targetPlayerIndex {
                guard let numOfCards = gameData?.numOfCards else { return }
//                print("dealing \(numOfCards) cards to player \(targetPlayerIndex)")
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
//                    print("player \(player.displayName) sent the shuffled deck")
                    deck.removeAll()
                    deck = receivedCards
                case "reshuffle":
                    discardPile.removeFirst(reshuffleCount)
                    deck.append(contentsOf: receivedCards)
                default:
                    return
                }
            }
        }
    }
