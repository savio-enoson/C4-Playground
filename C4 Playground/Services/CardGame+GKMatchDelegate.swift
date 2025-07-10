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
    
    //  TODO: Several things of note here. First look at the case "ready" block.
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
//        print("local player \(localPlayer.displayName) receiving data:")
        // Decode the data representation of the game data.
        let gameData = decode(matchData: data)
//        
//        //      Event handlers
//        //      Playing a card
        if let playedCard = gameData?.playedCard {
//            switch playedCard.cardType {
//            case .number:
//                
//            case .action:
//                switch playedCard.actionCardType {
//                    
//                }
//            }
            print("\(player.displayName) is playing a card.")
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
            print("dealing \(numOfCards) cards to player \(players[targetPlayerIndex].displayName)")
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
                print("player \(player.displayName) sent the shuffled deck")
                deck.removeAll()
                deck = receivedCards
                // Tell host deck has been received
                do {
                    let data = encode(message: "receivedDeck")
                    try match.send(data!, to: [host], dataMode: GKMatch.SendDataMode.reliable)
                } catch {
                    print("Error: \(error.localizedDescription).")
                }
            case "reshuffle":
                discardPile.removeFirst(discardPile.count - 1)
                deck.append(contentsOf: receivedCards)
                // Tell host reshuffled deck has been received
                do {
                    let data = encode(message: "receivedReshuffledDeck")
                    try match.send(data!, to: [player], dataMode: GKMatch.SendDataMode.reliable)
                } catch {
                    print("Error: \(error.localizedDescription).")
                }
            default:
                return
            }
        }
        else if let message = gameData?.message {
            // Message + Number = Adjust a gameplay var
            if let adjustBy = gameData?.adjustBy {
                switch message {
                case "updateTurn":
                    whoseTurn = adjustBy
                case "changeLimit":
                    changeLimit(amount: adjustBy)
                case "checkTurn":
                    let alivePlayerCount = playerIsEliminated.filter { $0 == false }.count
                    playersConfirmedTurn += 1
                    receivedWhoseTurnValues.append(adjustBy)
                    if playersConfirmedTurn == alivePlayerCount {
                        receivedWhoseTurnValues.append(whoseTurn)
                        let uniqueValues = Set(receivedWhoseTurnValues).count
                        if uniqueValues > 1 {
                            let confirmedTurn = findMostFrequent(in: receivedWhoseTurnValues)
                            whoseTurn = confirmedTurn!
                            
                            do {
                                let data = encode(message: "updateTurn", adjustBy: confirmedTurn!)
                                try match.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
                            } catch {
                                print("Error: \(error.localizedDescription).")
                            }
                            
                            playersConfirmedTurn = 0
                            receivedWhoseTurnValues.removeAll()
                        }
                    }
                default:
                    print("not yet set")
                }
                
            } else {
            // Message Only = Updating some status
                switch message {
                //  Only host will receive this. When a player sends the message, increment playersReady by 1. When the counter reaches the number of expected pings, the match can begin.
                //  TODO: Double click the createDeck function and jump to definition.
                case "ready":
                    if localPlayer == host {
                        print("received ready message from \(player.displayName)")
                        
                        playersReady += 1
                        if playersReady == match.players.count {
                            createDeck()
                        }
                    }
                //  Same as before, but this time the controller is in GameView
                //  TODO: Go to GameView and look for the first onChangeOf
                case "receivedDeck":
                    if localPlayer == host {
                        print("player \(player.displayName) has received the deck")
                        playersReceivedDeck += 1
                    }
                case "receivedReshuffledDeck":
                    playersReceivedReshuffleCMD += 1
                
                default:
                    return
                }
            }
        }
    }
}
