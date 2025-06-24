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
    case jinx_dog = "jinx_dog"
    case jinx_confusion = "jinx_confusion"
    case jinx_hallucination = "jinx_hallucination"
    
    case trump_wipeout = "trump_wipeout"
    case trump_maxout = "trump_maxout"
    case trump_limitchange = "trump_limitchange"
}

enum CardType: String, CaseIterable, Codable {
    case number, action
}

// MARK: - Card Model
struct Card: Identifiable, Equatable, Codable {
    let id: UUID
    let cardType: CardType
    var value: CardValue
    
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
        isFaceUp: Bool = false,
        discardOffset: CGPoint? = nil,
        discardRotation: Double? = nil,
        offsetScale: Double = 12.0)
    {
        self.id = id
        self.cardType = cardType
        self.value = value
        
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

struct StatusEffect {
    let type: CardValue
    let duration: Int
    let timeElapsed: Int? = 0
}
