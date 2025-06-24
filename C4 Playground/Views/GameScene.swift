////
////  GameSpriteView.swift
////  C4 Playground
////
////  Created by Gerald Gavin Lienardi on 23/06/25.
////
//
//import SpriteKit
//import GameKit
//import SwiftUI
//
//class GameScene: SKScene {
//    
////    Initializing the Game
//    var game: CardGame
//    
////    Variables regarding game setup
//    private var playAreaNode: SKShapeNode?
//    private var statusLabel: SKLabelNode!
//
//    
////    Variables regarding touch and stuff
//    private var selectedCard: CardNode? = nil
//    private var highestZPosition: CGFloat = 0
//    private var lastTouchLocation: CGPoint?
//    private var dragStartLocation: CGPoint?
//    private var isDragging: Bool = false
//    
//    private var dealTo: Int = 0
//    
//    init(size: CGSize, game: CardGame) {
//        self.game = game
//        super.init(size: size)
//        self.scaleMode = .resizeFill
//    }
//    
////    DISPLAY SETUP
//    override func didMove(to view: SKView) {
//        backgroundColor = SKColor(red: 45/255, green: 101/255, blue: 80/255, alpha: 1)
//        layoutCards(game.playerHands)
//        layoutPlayArea()
//        layoutDeck(deck: game.deck)
//        layoutTally()
//    }
// 
//    private func layoutCards(_ hands: [[Card]]){
//        let seatPositions: [Int] = (0..<game.players.count).map { (game.localPlayerIndex + $0) % game.players.count }
//
//        for seatIndex in 0..<seatPositions.count {
//            let playerIndex = seatPositions[seatIndex]
//            let hand = hands[playerIndex]
//            let isFaceUp = (playerIndex == game.localPlayerIndex)
//            
//            let seat: SeatPosition
//            switch seatIndex {
//            case 0: seat = .bottom
//            case 1: seat = .left
//            case 2: seat = .top
//            case 3: seat = .right
//            default: continue // support only 4 players
//            }
//
//            layoutPlayer(at: seat, with: hand, isFaceUp: isFaceUp)
//        }
//
//    }
//    
//    private func layoutPlayer(at seat: SeatPosition, with cards: [Card], isFaceUp: Bool) {
//        for (index, card) in cards.enumerated() {
//            let cardNode = CardNode(card: card, isFaceUp: isFaceUp)
//            let spacing: CGFloat = 70
//            var position: CGPoint = .zero
//            var rotation: CGFloat = 0
//
//            switch seat {
//            case .bottom:
//                let totalWidth = CGFloat(cards.count - 1) * spacing
//                let startX = (size.width - totalWidth) / 2
//                position = CGPoint(x: startX + CGFloat(index) * spacing, y: 100)
//                rotation = 0
//
//            case .top:
//                let totalWidth = CGFloat(cards.count - 1) * spacing
//                let startX = (size.width - totalWidth) / 2
//                position = CGPoint(x: startX + CGFloat(index) * spacing, y: size.height - 100)
//                rotation = .pi
//
//            case .left:
//                let totalHeight = CGFloat(cards.count - 1) * spacing
//                let startY = (size.height - totalHeight) / 2
//                position = CGPoint(x: 100, y: startY + CGFloat(index) * spacing)
//                rotation = -.pi / 2
//
//            case .right:
//                let totalHeight = CGFloat(cards.count - 1) * spacing
//                let startY = (size.height - totalHeight) / 2
//                position = CGPoint(x: size.width - 100, y: startY + CGFloat(index) * spacing)
//                rotation = .pi / 2
//            }
//
//            cardNode.position = position
//            cardNode.zRotation = rotation
//            cardNode.zPosition = 0
//            addChild(cardNode)
//        }
//    }
//    
//    private func layoutHand(_ hand: [Card], isFaceUp: Bool, seatPosition: Int) {
//        for (_, card) in hand.enumerated() {
//            let cardNode = CardNode(card: card, isFaceUp: isFaceUp)
//            // Add position/rotation logic here as needed
//            addChild(cardNode)
//        }
//    }
//    
//    private func layoutDeck(deck: [Card]) {
//        guard let playArea = playAreaNode else { return }
//
//        let basePosition = CGPoint(x: playArea.frame.maxX, y: playArea.frame.midY)
//
//        for (i, card) in deck.enumerated() {
//            let cardNode = CardNode(card: card, isFaceUp: false)
//            
//            // Offset each card slightly upwards by 1 point
//            let offset = CGFloat(i) * 1.0
//            cardNode.position = CGPoint(x: basePosition.x, y: basePosition.y + offset)
//
//            cardNode.zPosition = CGFloat(i)  // ensures visual stacking order
//            cardNode.name = "deck_card_\(i)"
//            addChild(cardNode)
//        }
//    }
//
//    
//    func layoutPlayArea(){
//        let size = CGSize(width: 500, height: 400)
//        let rect = CGRect(origin: .zero, size: size)
//        let node = SKShapeNode(rect: rect, cornerRadius: 12)
//
//        // Center the node in the scene
//        node.position = CGPoint(
//            x: (self.size.width - size.width) / 2,
//            y: (self.size.height - size.height) / 2
//        )
//
//        node.strokeColor = .white
//        node.lineWidth = 4
//        node.zPosition = -1
//        node.name = "playArea"
//
//        addChild(node)
//        playAreaNode = node
//    }
//    
//    private func layoutTally() {
//        let label = SKLabelNode(text: "Tally\n")
//        label.fontName = "AvenirNext-Bold"
//        label.fontSize = 28
//        label.fontColor = .white
//        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        label.zPosition = 1000 // on top of everything
//        label.name = "statusLabel"
//        addChild(label)
//        statusLabel = label // keep a reference
//    }
//    
//    func updateStatus(_ message: String) {
//        statusLabel.text = message
//    }
//    
////    TOUCH HANDLING
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return }
//        let location = touch.location(in: self)
//
//        let touchedCard = nodes(at: location).compactMap { $0 as? CardNode }.first
//        
//        // Check if this card belongs to the local player
//        guard let cardNode = touchedCard else { return }
//        
//        let localHand = game.playerHands[game.localPlayerIndex]
//
//        guard localHand.contains(where: { $0 == cardNode.card }) else {
//            print("❌ Touched card does not belong to local player")
//            return
//        }
//        
//        
//        if let newCard = touchedCard {
//            // If selecting a new card, scale down the old one
//            if selectedCard != newCard {
//                selectedCard?.run(SKAction.scale(to: 1.0, duration: 0.1))
//            }
//
//            selectedCard = newCard
//            dragStartLocation = location
//            lastTouchLocation = location
//            isDragging = false
//
//            highestZPosition += 1
//            selectedCard?.zPosition = highestZPosition
//
//            // Scale up the newly selected card
//            selectedCard?.run(SKAction.scale(to: 1.1, duration: 0.1))
//        } else {
//            // Tapped on empty space — deselect current card
//            if let previouslySelected = selectedCard {
//                previouslySelected.run(SKAction.scale(to: 1.0, duration: 0.1))
//            }
//
//            selectedCard = nil
//            dragStartLocation = nil
//            lastTouchLocation = nil
//            isDragging = false
//        }
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first,
//              let selectedCard = selectedCard,
//              let lastLocation = lastTouchLocation,
//              let startLocation = dragStartLocation else { return }
//
//        let currentLocation = touch.location(in: self)
//        let distance = hypot(currentLocation.x - startLocation.x, currentLocation.y - startLocation.y)
//
//        if !isDragging && distance > 10 {
//            isDragging = true // started dragging!
//        }
//
//        if isDragging {
//            let delta = CGPoint(x: currentLocation.x - lastLocation.x,
//                                y: currentLocation.y - lastLocation.y)
//            selectedCard.position = CGPoint(
//                x: selectedCard.position.x + delta.x,
//                y: selectedCard.position.y + delta.y
//            )
//            lastTouchLocation = currentLocation
//        }
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let selectedCard = selectedCard else { return }
//
//        // Reset drag state
//        lastTouchLocation = nil
//        dragStartLocation = nil
//        isDragging = false
//
//        // Animate scale down
////        selectedCard.run(SKAction.scale(to: 1.0, duration: 0.1))
//
//        if let playArea = playAreaNode {
//            // Check if the card's frame overlaps the play area
//            if playArea.frame.intersects(selectedCard.frame) {
//                print("✅ Card played in hitbox area: \(selectedCard.card)")
//
//                // 🔁 Flip if face-down
//                if !selectedCard.isFaceUp {
//                    selectedCard.flipToFaceUp()
//                }
//                
//                // Create random position offset
//                let offsetX = CGFloat.random(in: -50...50)
//                let offsetY = CGFloat.random(in: -50...50)
//                let snapPosition = CGPoint(
//                    x: playArea.frame.midX + offsetX,
//                    y: playArea.frame.midY + offsetY
//                )
//
//                // Create random angle offset in radians
//                let angle = CGFloat.random(in: -15...15) * (.pi / 180)
//
//                // Animate move and rotation together
//                let move = SKAction.move(to: snapPosition, duration: 0.2)
//                move.timingMode = .easeInEaseOut
//
//                let rotate = SKAction.rotate(toAngle: angle, duration: 0.2, shortestUnitArc: true)
//
//                let snap = SKAction.group([move, rotate])
//                selectedCard.run(snap)
//                // Animate scale down
//                selectedCard.run(SKAction.scale(to: 1.0, duration: 0.1))
//                
//                // ✅ Add a new card to the scene
//                dealTo = (dealTo + 1) % game.players.count
//
//                // Optional: mark card as "played" here
//            } else {
//                print("❌ Card dropped outside hitbox")
//            }
//        }
//
//        // Tap logic (if it wasn’t dragged)
//        if !isDragging {
//            print("Tapped card: \(selectedCard.card)")
//        }
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        touchesEnded(touches, with: event)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//
//struct GameScenePreview: View {
//    var scene: GameScene {
//        let mockGame = MockCardGame()
//        mockGame.setupMockGame()
//        mockGame.createDeck()
//        mockGame.startGame()
//        return GameScene(size: UIScreen.main.bounds.size, game: mockGame)
//    }
//
//    var body: some View {
//        SpriteView(scene: scene)
//            .ignoresSafeArea()
//    }
//}
//
//
//
//#Preview {
//    GameScenePreview()
//}
