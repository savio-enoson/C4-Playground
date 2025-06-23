//
//  TestSpriteView.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 20/06/25.
//

import SwiftUI
import SpriteKit

struct TestSpriteView: View {
    var hands: [[Card]]

        var body: some View {
            ZStack {
                SpriteView(scene: makeScene())
                    .ignoresSafeArea()
                    .zIndex(0)
                    .background(Color.clear)
                VStack {
                    Text("This is my deck of cards")
                        .foregroundStyle(.white)
                }
            }
            .frame(width: .infinity, height: .infinity)
            .background(Color.white)
        }

        private func makeScene() -> SKScene {
            let scene = CardScene(size: CGSize(width: 400, height: 200), hands: hands)
            return scene
        }
}

import SpriteKit

class CardScene: SKScene {
    let localPlayerIndex: Int = 0
    var players: [Int] = [0, 1, 2, 3]
    
    private var hands: [[Card]]
    private var selectedCard: CardNode? = nil
    
    private var highestZPosition: CGFloat = 0
    private var lastTouchLocation: CGPoint?
    private var dragStartLocation: CGPoint?
    private var isDragging: Bool = false
    
    private var dealTo: Int = 0
    private var deck: [Card] = []
    private var deckCardNodes: [CardNode] = []

    private var playAreaNode: SKShapeNode?

    init(size: CGSize, hands: [[Card]]) {
        self.hands = hands
        super.init(size: size)
        self.scaleMode = .resizeFill
        self.backgroundColor = .clear
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        layoutCards(hands)
        setupPlayArea()
        layoutDeck()
    }

    private func layoutCards(_ allCards: [[Card]]){
        let seatPositions: [Int] = (0..<players.count).map { (localPlayerIndex + $0) % players.count }

        for seatIndex in 0..<seatPositions.count {
            let playerIndex = seatPositions[seatIndex]
            let hand = allCards[playerIndex]
            let isFaceUp = (playerIndex == localPlayerIndex)
            
            let seat: SeatPosition
            switch seatIndex {
            case 0: seat = .bottom
            case 1: seat = .left
            case 2: seat = .top
            case 3: seat = .right
            default: continue // support only 4 players
            }

            layoutPlayer(at: seat, with: hand, isFaceUp: isFaceUp)
        }

    }
    
    private func layoutDeck() {
        // Clear any existing nodes
        deckCardNodes.forEach { $0.removeFromParent() }
        deckCardNodes.removeAll()
        deck.removeAll()

        // Create and shuffle deck
        let subtractCards = CardValue.allCases.filter { $0.rawValue.starts(with: "-") }
            .flatMap { value in (0..<3).map { _ in Card(cardType: .number, value: value) } }

        let addCards = CardValue.allCases.filter {
            !$0.rawValue.starts(with: "-") &&
            !$0.rawValue.starts(with: "trump_") &&
            !$0.rawValue.starts(with: "jinx_") &&
            Int($0.rawValue) != nil
        }
        .flatMap { value in (0..<5).map { _ in Card(cardType: .number, value: value) } }

        let jinxCards = (0..<5).map { _ in
            Card(cardType: .action, value: .jinx_banana, actionCardType: .jinx, jinxType: .banana)
        }

        let trumpCards = [
            (0..<4).map { _ in Card(cardType: .action, value: .trump_wipeout, actionCardType: .trump, trumpType: .wipeout) },
            (0..<4).map { _ in Card(cardType: .action, value: .trump_maxout, actionCardType: .trump, trumpType: .maxout) },
            (0..<4).map { _ in Card(cardType: .action, value: .trump_limitchange, actionCardType: .trump, trumpType: .limitchange) }
        ].flatMap { $0 }

        deck.append(contentsOf: subtractCards + addCards + jinxCards + trumpCards)
        deck.shuffle()

        // Visually stack all cards in one place (e.g., top-right of playArea)
        guard let playArea = playAreaNode else { return }

        let basePosition = CGPoint(x: playArea.frame.maxX + 60, y: playArea.frame.midY)

        for (i, card) in deck.enumerated() {
            let cardNode = CardNode(card: card, false) // Face-down
            cardNode.zPosition = CGFloat(i)
            cardNode.position = basePosition
            cardNode.name = "deck_card_\(i)"
            addChild(cardNode)
            deckCardNodes.append(cardNode)
        }
    }
    
    private func layoutHand(_ hand: [Card], isFaceUp: Bool, seatPosition: Int) {
        for (index, card) in hand.enumerated() {
            let cardNode = CardNode(card: card, isFaceUp)
            // Add position/rotation logic here as needed
            addChild(cardNode)
        }
    }
    
    private func layoutPlayer(at seat: SeatPosition, with cards: [Card], isFaceUp: Bool) {
        for (index, card) in cards.enumerated() {
            let cardNode = CardNode(card: card, isFaceUp)
            let spacing: CGFloat = 70
            var position: CGPoint = .zero
            var rotation: CGFloat = 0

            switch seat {
            case .bottom:
                let totalWidth = CGFloat(cards.count - 1) * spacing
                let startX = (size.width - totalWidth) / 2
                position = CGPoint(x: startX + CGFloat(index) * spacing, y: 100)
                rotation = 0

            case .top:
                let totalWidth = CGFloat(cards.count - 1) * spacing
                let startX = (size.width - totalWidth) / 2
                position = CGPoint(x: startX + CGFloat(index) * spacing, y: size.height - 100)
                rotation = .pi

            case .left:
                let totalHeight = CGFloat(cards.count - 1) * spacing
                let startY = (size.height - totalHeight) / 2
                position = CGPoint(x: 100, y: startY + CGFloat(index) * spacing)
                rotation = -.pi / 2

            case .right:
                let totalHeight = CGFloat(cards.count - 1) * spacing
                let startY = (size.height - totalHeight) / 2
                position = CGPoint(x: size.width - 100, y: startY + CGFloat(index) * spacing)
                rotation = .pi / 2
            }

            cardNode.position = position
            cardNode.zRotation = rotation
            cardNode.zPosition = 0
            addChild(cardNode)
        }
    }
    
    private func setupPlayArea() {
        let size = CGSize(width: 500, height: 400)
        let rect = CGRect(origin: .zero, size: size)
        let node = SKShapeNode(rect: rect, cornerRadius: 12)

        // Center the node in the scene
        node.position = CGPoint(
            x: (self.size.width - size.width) / 2,
            y: (self.size.height - size.height) / 2
        )

        node.strokeColor = .green
        node.lineWidth = 4
        node.zPosition = -1
        node.name = "playArea"

        addChild(node)
        playAreaNode = node
    }


    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let touchedCard = nodes(at: location).compactMap { $0 as? CardNode }.last

        if let newCard = touchedCard {
            // If selecting a new card, scale down the old one
            if selectedCard != newCard {
                selectedCard?.run(SKAction.scale(to: 1.0, duration: 0.1))
            }

            selectedCard = newCard
            dragStartLocation = location
            lastTouchLocation = location
            isDragging = false

            highestZPosition += 1
            selectedCard?.zPosition = highestZPosition

            // Scale up the newly selected card
            selectedCard?.run(SKAction.scale(to: 1.1, duration: 0.1))
        } else {
            // Tapped on empty space — deselect current card
            if let previouslySelected = selectedCard {
                previouslySelected.run(SKAction.scale(to: 1.0, duration: 0.1))
            }

            selectedCard = nil
            dragStartLocation = nil
            lastTouchLocation = nil
            isDragging = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let selectedCard = selectedCard,
              let lastLocation = lastTouchLocation,
              let startLocation = dragStartLocation else { return }

        let currentLocation = touch.location(in: self)
        let distance = hypot(currentLocation.x - startLocation.x, currentLocation.y - startLocation.y)

        if !isDragging && distance > 10 {
            isDragging = true // started dragging!
        }

        if isDragging {
            let delta = CGPoint(x: currentLocation.x - lastLocation.x,
                                y: currentLocation.y - lastLocation.y)
            selectedCard.position = CGPoint(
                x: selectedCard.position.x + delta.x,
                y: selectedCard.position.y + delta.y
            )
            lastTouchLocation = currentLocation
        }
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let selectedCard = selectedCard else { return }

        // Reset drag state
        lastTouchLocation = nil
        dragStartLocation = nil
        isDragging = false

        // Animate scale down
//        selectedCard.run(SKAction.scale(to: 1.0, duration: 0.1))

        if let playArea = playAreaNode {
            // Check if the card's frame overlaps the play area
            if playArea.frame.intersects(selectedCard.frame) {
                print("✅ Card played in hitbox area: \(selectedCard.card)")

                // 🔁 Flip if face-down
                if !selectedCard.isFaceUp {
                    selectedCard.flipToFaceUp()
                }
                
                // Create random position offset
                let offsetX = CGFloat.random(in: -1...1)
                let offsetY = CGFloat.random(in: -5...5)
                let snapPosition = CGPoint(
                    x: playArea.frame.midX + offsetX,
                    y: playArea.frame.midY + offsetY
                )

                // Create random angle offset in radians
                let angle = CGFloat.random(in: -15...15) * (.pi / 180)

                // Animate move and rotation together
                let move = SKAction.move(to: snapPosition, duration: 0.2)
                move.timingMode = .easeInEaseOut

                let rotate = SKAction.rotate(toAngle: angle, duration: 0.2, shortestUnitArc: true)

                let snap = SKAction.group([move, rotate])
                selectedCard.run(snap)
                // Animate scale down
                selectedCard.run(SKAction.scale(to: 1.0, duration: 0.1))
                
                // ✅ Add a new card to the scene
                addNewCardToHand(toPlayerIndex: dealTo)
                dealTo = (dealTo + 1) % players.count

                // Optional: mark card as "played" here
            } else {
                print("❌ Card dropped outside hitbox")
            }
        }

        // Tap logic (if it wasn’t dragged)
        if !isDragging {
            print("Tapped card: \(selectedCard.card)")
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    
    func addNewCardToHand(toPlayerIndex: Int) {
        guard !deck.isEmpty, !deckCardNodes.isEmpty else {
            print("Deck is empty!")
            return
        }

        // 1. Pop card & node from deck
        let card = deck.removeLast()
        let cardNode = deckCardNodes.removeLast()
        
        cardNode.zPosition = highestZPosition
        highestZPosition += 1

        // 2. Mark face up if local player
        let isFaceUp = (toPlayerIndex == localPlayerIndex)
        if isFaceUp {
            cardNode.flipToFaceUp()
        }

        // 3. Add to hand model
        hands[toPlayerIndex].append(card)

        // 4. Determine seat position (0 = local player at bottom)
        let relativeSeat = (toPlayerIndex - localPlayerIndex + players.count) % players.count

        let spacing: CGFloat = 70
        let cardIndex = hands[toPlayerIndex].count - 1
        var position: CGPoint = .zero
        var rotation: CGFloat = 0

        switch relativeSeat {
        case 0: // bottom
            let totalWidth = CGFloat(hands[toPlayerIndex].count - 1) * spacing
            let startX = (size.width - totalWidth) / 2
            position = CGPoint(x: startX + CGFloat(cardIndex) * spacing, y: 100)
            rotation = 0

        case 1: // left
            let totalHeight = CGFloat(hands[toPlayerIndex].count - 1) * spacing
            let startY = (size.height - totalHeight) / 2
            position = CGPoint(x: 100, y: startY + CGFloat(cardIndex) * spacing)
            rotation = -.pi / 2

        case 2: // top
            let totalWidth = CGFloat(hands[toPlayerIndex].count - 1) * spacing
            let startX = (size.width - totalWidth) / 2
            position = CGPoint(x: startX + CGFloat(cardIndex) * spacing, y: size.height - 100)
            rotation = .pi

        case 3: // right
            let totalHeight = CGFloat(hands[toPlayerIndex].count - 1) * spacing
            let startY = (size.height - totalHeight) / 2
            position = CGPoint(x: size.width - 100, y: startY + CGFloat(cardIndex) * spacing)
            rotation = .pi / 2

        default:
            print("⚠️ Unsupported seat position")
            return
        }

        // 5. Animate move + optional swing
        cardNode.zPosition = 50
        let move = SKAction.move(to: position, duration: 0.3)
        move.timingMode = .easeOut

        let rotateToTarget = SKAction.rotate(toAngle: rotation, duration: 0.2, shortestUnitArc: true)
        let rotateRight = SKAction.rotate(byAngle: .pi / 16, duration: 0.1)
        let rotateLeft = SKAction.rotate(byAngle: -.pi / 32, duration: 0.15)
        let rotateCenter = SKAction.rotate(toAngle: rotation, duration: 0.2)
        let swing = SKAction.sequence([rotateRight, rotateLeft, rotateCenter])

        let animation = SKAction.group([move, rotateToTarget, swing])

        cardNode.run(animation)
    }




    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    let hands: [[Card]] = [
        [
            Card(cardType: .number, value: .add_1),
            Card(cardType: .number, value: .subtract_2),
            Card(cardType: .number, value: .add_3)
        ],
        [
            Card(cardType: .number, value: .add_1),
            Card(cardType: .number, value: .subtract_2),
            Card(cardType: .number, value: .add_3)
        ],
        [
            Card(cardType: .number, value: .add_1),
            Card(cardType: .number, value: .subtract_2),
            Card(cardType: .number, value: .add_3)
        ],
        [
            Card(cardType: .number, value: .add_1),
            Card(cardType: .number, value: .subtract_2),
            Card(cardType: .number, value: .add_3)
        ]
    ]
    TestSpriteView(hands: hands)
}


enum SeatPosition{
    case bottom, left, top, right
}
