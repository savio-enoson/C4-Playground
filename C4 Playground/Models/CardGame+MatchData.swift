//
//  CardGame+MatchData.swift
//  C4 Playground
//
//  Created by Savio Enoson on 14/06/25.
//

import SwiftUI
import Foundation
import GameKit

struct GameData: Codable {
    var playerIndex: Int?
    var playedCard: Card?
    var indexInHand: Int?
    var targetPlayerIndex: Int?
    var numOfCards: Int?
    var listOfCards: [Card]?
    
    var message: String?
    // For adjusting the limit
    var adjustment: Int?
}

extension CardGame {
    // MARK: Codable Game Data
    
    /// Creates a data representation of the local player's score for sending to other players.
    // Playing a number card
    func encode(playedCard: Card, indexInHand: Int) -> Data? {
        let gameData = GameData(playerIndex: self.localPlayerIndex, playedCard: playedCard, indexInHand: indexInHand)
        return encode(gameData: gameData)
    }
    
    // Dealing a card
    func encode(targetPlayerIndex: Int, numOfCards: Int) -> Data? {
        let gameData = GameData(targetPlayerIndex: targetPlayerIndex, numOfCards: numOfCards)
        return encode(gameData: gameData)
    }
    
    // Playing an action card
    func encode(playedCard: Card, targetPlayerIndex: Int) -> Data? {
        let gameData = GameData(playerIndex: self.localPlayerIndex, playedCard: playedCard, targetPlayerIndex: targetPlayerIndex)
        return encode(gameData: gameData)
    }
    
    // Modify the encode function to include adjustment
    func encode(playedCard: Card, indexInHand: Int, adjustment: Int? = nil) -> Data? {
        let gameData = GameData(
            playerIndex: self.localPlayerIndex,
            playedCard: playedCard,
            indexInHand: indexInHand,
            adjustment: adjustment
        )
        return encode(gameData: gameData)
    }
    
    // Message without target (player busted)
    func encode(message: String) -> Data? {
        let gameData = GameData(playerIndex: self.localPlayerIndex, message: message)
        return encode(gameData: gameData)
    }
    
    // Sending a message with targetPlayerIndex (for Jinx targeting like Banana)
    func encode(message: String, targetPlayerIndex: Int) -> Data? {
        let gameData = GameData(playerIndex: self.localPlayerIndex, targetPlayerIndex: targetPlayerIndex, message: message)
        return encode(gameData: gameData)
    }
    
    // Modify deck or discard pile
    func encode(message: String, listOfCards: [Card]) -> Data? {
        let gameData = GameData(listOfCards: listOfCards, message: message)
        return encode(gameData: gameData)
    }
    
    /// Creates a data representation of game data for sending to other players.
    ///
    /// - Returns: A representation of game data.
    func encode(gameData: GameData) -> Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(gameData)
            return data
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Decodes a data representation of match data from another player.
    ///
    /// - Parameter matchData: A data representation of the game data.
    /// - Returns: A game data object.
    func decode(matchData: Data) -> GameData? {
        // Convert the data object to a game data object.
        return try? PropertyListDecoder().decode(GameData.self, from: matchData)
    }
}
