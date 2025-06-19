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
    
//    case two = "2"
//    case three = "3"
//    case four = "4"
//    case five = "5"
//    case six = "6"
//    case seven = "7"
//    case eight = "8"
//    case nine = "9"
//    case ten = "10"
//    case jack = "-10"
//    case queen = "-20"
//    case king = "100"
//    case ace = "1"
//    
//    var imageName: String {
//        switch self {
//        case .ace: return "ace"
//        case .jack: return "jack"
//        case .queen: return "queen"
//        case .king: return "king"
//        default: return self.rawValue
//        }
//    }
}

// MARK: - Card Suit Enum
//enum CardSuit: String, CaseIterable, Codable {
//    case diamonds, clubs, hearts, spades
//    
//    var imageName: String {
//        self.rawValue
//    }
//}

enum CardType: String, CaseIterable, Codable {
    case number, action
}

enum ActionCardType: String, CaseIterable, Codable {
    case skipTurn, passTurn, divide
}

// MARK: - Card Model
struct Card: Identifiable, Equatable, Codable {
    let id: UUID
    let cardType: CardType
    
    let value: CardValue
//    let suit: CardSuit  // To be removed when changing later
    var actionCardType: ActionCardType? = nil   // Action card types (enum). Use switch case to trigger different effects later
    
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
        isFaceUp: Bool = false,
        discardOffset: CGPoint? = nil,
        discardRotation: Double? = nil,
        offsetScale: Double = 12.0)
    {
        self.id = id
        self.cardType = cardType
        self.value = value
//        self.suit = suit
        self.actionCardType = actionCardType ?? nil
        
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
