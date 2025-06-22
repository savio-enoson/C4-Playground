import Foundation
import SwiftUI

// MARK: - Card Value Enum
enum CardValue: String, CaseIterable, Codable {
    case add_1 = "1"
    case add_2 = "2"
    case add_3 = "3"
    case add_4 = "4"
    case add_5 = "5"
    
    case subtract_1 = "-1"
    case subtract_2 = "-2"
    case subtract_3 = "-3"
    case subtract_4 = "-4"
    case subtract_5 = "-5"
    
    case jinx_banana = "jinx_banana"
    
    case trump_wipeout = "trump_wipeout"
    case trump_maxout = "trump_maxout"
    case trump_invert = "trump_invert"
}

enum CardType: String, CaseIterable, Codable {
    case number, action
}

enum ActionCardType: String, CaseIterable, Codable {
    case jinx, trump
}

// Status Effect Jokers that affect a player's hand or their gameplay experience.
enum JinxType: String, Codable {
    case dog, banana
}

// Jokers that affect the tally, rules or flow of the game.
enum TrumpType: String, Codable {
    case wipeout, maxout, invert
}

// MARK: - Card Model
struct Card: Identifiable, Equatable, Codable {
    let id: UUID
    let cardType: CardType
    
    let value: CardValue
//    let suit: CardSuit  // To be removed when changing later
    var actionCardType: ActionCardType? = nil   // Action card types (enum). Use switch case to trigger different effects later
    var jinxType: JinxType? = nil
    var trumpType: TrumpType? = nil
    // Variables to remember the card's offset and rotation inside the discard pile
    var discardOffset: CGPoint?
    var discardRotation: Double?
    var offsetScale: Double
    
    // Computed property - marked as transient (won't be encoded)
    var imageName: String {
        "card_\(value)"
    }
    
    init(
        id: UUID = UUID(),
        cardType: CardType,
        value: CardValue,
    //  suit: CardSuit,
        actionCardType: ActionCardType? = nil,
        jinxType: JinxType? = nil,
        trumpType: TrumpType? = nil,
        isFaceUp: Bool = false,
        discardOffset: CGPoint? = nil,
        discardRotation: Double? = nil,
        offsetScale: Double = 12.0)
    {
        self.id = id
        self.cardType = cardType
        self.value = value
//        self.suit = suit
        self.actionCardType = actionCardType
        self.jinxType = jinxType
        self.trumpType = trumpType
        
        self.discardOffset = discardOffset
        self.discardRotation = discardRotation
        self.offsetScale = offsetScale
    }
    
    // Mutating func to change / set the discard offset
    mutating func setDiscardPosition(index: Int) {
        guard discardOffset == nil else { return }
        discardOffset = CGPoint(
            x: offsetScale + CGFloat.random(in: -3...3),
            y: offsetScale + CGFloat.random(in: -3...3)
        )
        discardRotation = offsetScale * Double.random(in: -3...3)
    }
}
