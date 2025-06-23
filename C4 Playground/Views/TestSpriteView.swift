//
//  TestSpriteView.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 20/06/25.
//

import SwiftUI
import SpriteKit

struct TestSpriteView: View {
    var cards: [Card]

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
            let scene = CardScene(size: CGSize(width: 400, height: 200), cards: cards)
            return scene
        }
}

import SpriteKit

class CardScene: SKScene {
    private var cards: [Card]
    private var selectedCard: CardNode? = nil
    private var highestZPosition: CGFloat = 0
    private var lastTouchLocation: CGPoint?
    private var dragStartLocation: CGPoint?
    private var isDragging: Bool = false

    private var playAreaNode: SKShapeNode?

    init(size: CGSize, cards: [Card]) {
        self.cards = cards
        super.init(size: size)
        self.scaleMode = .resizeFill
        self.backgroundColor = .clear
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        layoutCards()
        setupPlayArea()
    }

    private func layoutCards() {
        removeAllChildren()

        layoutPlayerOne(cards)
        layoutPlayerTwo(cards)
        layoutPlayerThree(cards)
        layoutPlayerFour(cards)
    }
    
    private func layoutPlayerOne(_ cards: [Card]) {
        // Bottom (Facing Up)
        for (index, card) in cards.enumerated() {
            let cardNode = CardNode(card: card)
            let spacing: CGFloat = 70
            let totalWidth = CGFloat(cards.count - 1) * spacing
            let startX = (size.width - totalWidth) / 2

            cardNode.position = CGPoint(x: startX + CGFloat(index) * spacing, y: 100)
            cardNode.zRotation = 0 // Facing up
            cardNode.zPosition = 0
            addChild(cardNode)
        }
    }

    private func layoutPlayerTwo(_ cards: [Card]) {
        // Left (Facing Right)
        for (index, card) in cards.enumerated() {
            let cardNode = CardNode(card: card)
            let spacing: CGFloat = 70
            let totalHeight = CGFloat(cards.count - 1) * spacing
            let startY = (size.height - totalHeight) / 2

            cardNode.position = CGPoint(x: 100, y: startY + CGFloat(index) * spacing)
            cardNode.zRotation = -.pi / 2 // 90° facing right
            cardNode.zPosition = 0
            addChild(cardNode)
        }
    }

    private func layoutPlayerThree(_ cards: [Card]) {
        // Top (Facing Down)
        for (index, card) in cards.enumerated() {
            let cardNode = CardNode(card: card)
            let spacing: CGFloat = 70
            let totalWidth = CGFloat(cards.count - 1) * spacing
            let startX = (size.width - totalWidth) / 2

            cardNode.position = CGPoint(x: startX + CGFloat(index) * spacing, y: size.height - 100)
            cardNode.zRotation = .pi // 180° facing down
            cardNode.zPosition = 0
            addChild(cardNode)
        }
    }

    private func layoutPlayerFour(_ cards: [Card]) {
        // Right (Facing Left)
        for (index, card) in cards.enumerated() {
            let cardNode = CardNode(card: card)
            let spacing: CGFloat = 70
            let totalHeight = CGFloat(cards.count - 1) * spacing
            let startY = (size.height - totalHeight) / 2

            cardNode.position = CGPoint(x: size.width - 100, y: startY + CGFloat(index) * spacing)
            cardNode.zRotation = .pi / 2 // -90° facing left
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

                // Create random position offset
                let offsetX = CGFloat.random(in: -30...30)
                let offsetY = CGFloat.random(in: -30...30)
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
                addNewCard()

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
    
    func addNewCard() {
        // Generate a random card value
        let allValues = CardValue.allCases
        let randomValue = allValues.randomElement() ?? .add_1

        // Create a new Card model
        let newCard = Card(
            cardType: .number,
            value: randomValue
        )

        // Append to internal tracking if needed
        cards.append(newCard)

        // Create the card node
        let cardNode = CardNode(card: newCard)
        
        // Set its starting position (e.g. spawn at top center)
        cardNode.position = CGPoint(x: size.width / 2, y: size.height - 100)
        cardNode.zPosition = 0
        addChild(cardNode)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    let cards: [Card] = [
        Card(cardType: .number, value: .add_1),
        Card(cardType: .number, value: .subtract_2),
        Card(cardType: .number, value: .add_3)
    ]
    TestSpriteView(cards: cards)
}
