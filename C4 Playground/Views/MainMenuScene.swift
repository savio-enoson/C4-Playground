//
//  MainMenuScene.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 24/06/25.
//

import SpriteKit
import GameKit
import SwiftUI

class MainMenuScene: SKScene {
    weak var cardGame: CardGame?
    private var selectedCard: CardNode? = nil
    private var lastTouchLocation: CGPoint?
    private var dragStartLocation: CGPoint?
    private var selectedCardOriginalPosition: CGPoint?
    private var isDragging: Bool = false
    
    private var ruleCards: [RuleCardNode] = []
    private var currentRuleIndex: Int = 0
    private var closeButton: SKSpriteNode?
    private var isShowingRules: Bool = false
    private var touchBlockerNode: SKShapeNode?


    
    var playedCards: [(node: CardNode, originalPosition: CGPoint, originalZPosition: CGFloat, originalZRotation: CGFloat)] = []

    var isPortrait: Bool {
        size.height >= size.width
    }
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var playAreaNode: SKShapeNode?
    
    override init(size: CGSize) {
        super.init(size: size)
        self.scaleMode = .resizeFill
    }
    
//    DISPLAY SETUP
    override func didMove(to view: SKView) {
        layoutScene()
        
        if let game = cardGame {
            game.playBackgroundMusic(named: "in_lobby")
        }
        
        // Avoid adding duplicates
        view.gestureRecognizers?.removeAll(where: { $0.name == "ruleSwipe" })

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        swipeLeft.name = "ruleSwipe"

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        swipeRight.name = "ruleSwipe"

        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScene()
    }

    private func layoutScene(){
        removeAllChildren()
        
        backgroundColor = SKColor(red: 45/255, green: 101/255, blue: 80/255, alpha: 1)
        
        setupTitle()
        cardFanOne()
//        cardFanTwo()
        setupMenuCards(
//            PLACEHOLDER - change the name of card_add_1 and card_add_2
            imageNames: ["cardBack", "card_startGame", "card_howToPlay", "cardBack"],
            angleOffsetDegrees: 180
        )
    }
    
    private func setupTitle(){
        let yMultiplier: CGFloat = isPortrait ? 0.75 : 0.7
        
        let baseSize = min(size.width, size.height)
        let heightFraction: CGFloat = isPortrait ? 0.3 : 0.3
        let dynamicHeight = baseSize * heightFraction

        let titleImage = SKSpriteNode(imageNamed: "game_title")
        titleImage.name = "title"
        titleImage.zPosition = 1000

        if let textureSize = titleImage.texture?.size() {
            let aspect = textureSize.width / textureSize.height
            titleImage.size = CGSize(width: dynamicHeight * aspect, height: dynamicHeight)
        }

        titleImage.position = CGPoint(x: size.width / 2, y: size.height * yMultiplier)
        addChild(titleImage)
        
//        Animation
        let bobbing = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 1.2),
            SKAction.moveBy(x: 0, y: -10, duration: 1.2)
        ])
        let loop = SKAction.repeatForever(bobbing)
        titleImage.run(loop)
        
        let squareLength = titleImage.size.width/1.5
        let size = CGSize(width: squareLength, height: squareLength)
        let rect = CGRect(origin: .zero, size: size)
        let node = SKShapeNode(rect: rect, cornerRadius: 12)

        // Center it under the title image
        node.position = CGPoint(
            x: titleImage.position.x - size.width / 2,
            y: titleImage.position.y - titleImage.size.height*2
        )

        node.strokeColor = SKColor(red: 45/255, green: 111/255, blue: 80/255, alpha: 1)
        node.lineWidth = 4
        node.zPosition = titleImage.zPosition - 1000  // Behind the title
        node.name = "playArea"

        addChild(node)
        playAreaNode = node
        
        let promptLabel = SKLabelNode(text: "Drag a card here...")
        promptLabel.fontName = "Jersey 10" // or your custom font name
        promptLabel.fontSize = titleImage.frame.height * 0.2
        promptLabel.fontColor = .white
        promptLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        promptLabel.zPosition = node.zPosition + 1
        promptLabel.alpha = 1.0 // Start invisible

        // Fade in and out forever
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 1.0)
        let pulse = SKAction.sequence([fadeIn, fadeOut])
        let loopAnimation = SKAction.repeatForever(pulse)
        promptLabel.run(loopAnimation)

        node.addChild(promptLabel)
    }
    
    private func setupMenuCards(
        imageNames: [String], // e.g. ["cardBack", "startIcon", "helpIcon", "cardBack"]
        spreadAngle: CGFloat = .pi / 3,
        angleOffsetDegrees: CGFloat = 0
    ) {
        let shortSide = min(size.width, size.height)

        let height = (shortSide / 2.5)
        
        let radius = height * 1.5
        
        let basePosition: CGPoint = {
            if isPortrait {
                return isPad
                ? CGPoint(x: size.width / 2, y: size.height * -0.3)  // iPad portrait
                    : CGPoint(x: size.width / 2, y: size.height * -0.2)   // iPhone portrait
            } else {
                return isPad
                ? CGPoint(x: size.width / 2, y: size.height * -0.5)    // iPad landscape
                : CGPoint(x: size.width / 2, y: size.height * -0.5)   // iPhone landscape
            }
        }()

        let angleOffset = angleOffsetDegrees * (.pi / 180)
        let angleIncrement = spreadAngle / CGFloat(max(imageNames.count - 1, 1))
        let startAngle = -spreadAngle / 2

        for (i, imageName) in imageNames.enumerated() {
            let angle = startAngle + CGFloat(i) * angleIncrement + angleOffset
            let baseX = basePosition.x + radius * sin(angle)
            let baseY = basePosition.y - radius * cos(angle)
            let position = CGPoint(x: baseX, y: baseY)

            let card = Card(cardType: .number, value: .add_1) // or any dummy value
            let cardNode = CardNode(card: card, fitToHeight: height, isFaceUp: true)

            cardNode.texture = SKTexture(imageNamed: imageName)
            cardNode.size = CGSize(width: height * (cardNode.texture!.size().width / cardNode.texture!.size().height), height: height)
            cardNode.name = imageName  // 👈 This line is crucial
            cardNode.position = position
            cardNode.zRotation = angle + .pi
            cardNode.zPosition = CGFloat(i)

            addChild(cardNode)

        }
    }

    func createDecorativeSprite(imageName: String, fitToHeight: CGFloat) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: imageName)
        let aspect = texture.size().width / texture.size().height
        let size = CGSize(width: fitToHeight * aspect, height: fitToHeight)
        return SKSpriteNode(texture: texture, size: size)
    }

    
    private func cardFanOne() {
        let shortSide = min(size.width, size.height)
        let longSide = max(size.width, size.height)

        let height = shortSide / 2.5

        // Base center position (slightly higher than center for portrait; adjusted in landscape)
        let basePosition: CGPoint = {
            if isPortrait {
                return isPad
                ? CGPoint(x: size.width * 1.05, y: size.height * 0.8)  // iPad portrait
                    : CGPoint(x: size.width * 1, y: size.height * 0.7)   // iPhone portrait
            } else {
                return isPad
                ? CGPoint(x: size.width * 1.05, y: size.height * 0.6)    // iPad landscape
                : CGPoint(x: size.width * 1, y: size.height * 0.5)   // iPhone landscape
            }
        }()

        let cards: [CardLayoutData] = [
            CardLayoutData(card: Card(cardType: .number, value: .subtract_3), xOffset: -height / 1.5, yOffset: 0,   zRotationDegrees: 25,  zPosition: 0),
            CardLayoutData(card: Card(cardType: .number, value: .add_5),      xOffset: -height / 3,  yOffset: height / 10,  zRotationDegrees: 15,  zPosition: 1),
            CardLayoutData(card: Card(cardType: .number, value: .add_2),      xOffset: height / 20,  yOffset: height/3,  zRotationDegrees: 0,   zPosition: 3),
            CardLayoutData(card: Card(cardType: .number, value: .subtract_1), xOffset: height / 2,   yOffset: height/3,  zRotationDegrees: -15, zPosition: 2),
            CardLayoutData(card: Card(cardType: .number, value: .subtract_4), xOffset: height / 1.1, yOffset: -height/10, zRotationDegrees: -20, zPosition: 4)
        ]

        layoutCardFanCustom(
            cards: cards,
            basePosition: basePosition,
            fanAngleDegrees: 115,
            fitToHeight: height
        )
    }

    private func cardFanTwo(){
        let shortSide = min(size.width, size.height)
        let longSide = max(size.width, size.height)

        let height = shortSide / 2.5
        
        // Base center position (slightly higher than center for portrait; adjusted in landscape)
        let basePosition: CGPoint = {
            if isPortrait {
                return isPad
                    ? CGPoint(x: size.width * -0.05, y: size.height * 0.35)  // iPad portrait
                    : CGPoint(x: size.width * -0.1, y: size.height * 0.6)   // iPhone portrait
            } else {
                return isPad
                    ? CGPoint(x: size.width * -0.05, y: size.height * 0.6)    // iPad landscape
                : CGPoint(x: size.width * -0.05, y: size.height * 0.5)   // iPhone landscape
            }
        }()
        
        let cards: [CardLayoutData] = [
            CardLayoutData(card: Card(cardType: .number, value: .add_5),      xOffset: -height/2,  yOffset: 30,  zRotationDegrees: 15, zPosition: 0),
            CardLayoutData(card: Card(cardType: .number, value: .add_5),      xOffset: -height/30,    yOffset: 75,  zRotationDegrees:   0, zPosition: -3),
            CardLayoutData(card: Card(cardType: .number, value: .subtract_1), xOffset: height/2,   yOffset: 55,  zRotationDegrees:  -15, zPosition: -1),
            CardLayoutData(card: Card(cardType: .number, value: .subtract_4), xOffset: height/1.2,  yOffset: -20,   zRotationDegrees:  -35, zPosition: -2),
            CardLayoutData(card: Card(cardType: .number, value: .add_3), xOffset: height*1.1,  yOffset: -height*0.3,   zRotationDegrees:  -50, zPosition: -3)
        ]
        
        layoutCardFanCustom(
            cards: cards,
            basePosition: basePosition,
            fanAngleDegrees: 300,
            fitToHeight: height
        )
    }
    
    func layoutCardFanCustom(
        cards: [CardLayoutData],
        basePosition: CGPoint,
        fanAngleDegrees: CGFloat = 0,
        fitToHeight: CGFloat = 180,
        isFaceUp: Bool = true
    ) {
        let fanRotation = fanAngleDegrees * (.pi / 180)

        for layout in cards {
            let rotatedX = cos(fanRotation) * layout.xOffset - sin(fanRotation) * layout.yOffset
            let rotatedY = sin(fanRotation) * layout.xOffset + cos(fanRotation) * layout.yOffset
            let finalPosition = CGPoint(
                x: basePosition.x + rotatedX,
                y: basePosition.y + rotatedY
            )

            let cardNode = CardNode(card: layout.card, fitToHeight: fitToHeight, isFaceUp: isFaceUp)
            cardNode.position = finalPosition
            cardNode.zRotation = layout.zRotationRadians + fanRotation
            cardNode.zPosition = layout.zPosition
            addChild(cardNode)
            
//            Remove this bit if animation is weird
            let bob = SKAction.sequence([
                SKAction.rotate(byAngle: .pi / 180 * 2, duration: 2.0),  // rotate 2°
                SKAction.rotate(byAngle: -.pi / 180 * 2, duration: 2.0)  // rotate -2°
            ])
            let bobForever = SKAction.repeatForever(bob)
            cardNode.run(bobForever)
        }
    }
    
    func showRuleCards() {
        selectedCard = nil
        guard !isShowingRules else { return }
        isShowingRules = true

        // Add a semi-transparent dark background blocker to catch all touches except on rules & close button
        let blocker = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        blocker.position = CGPoint(x: size.width / 2, y: size.height / 2)
        blocker.fillColor = SKColor.black.withAlphaComponent(0.5)
        blocker.zPosition = 1001  // Just below rules (which you set to 100+)
        blocker.name = "touchBlocker"
        blocker.isUserInteractionEnabled = false // We'll handle touches in scene

        addChild(blocker)
        touchBlockerNode = blocker

        let cardSize = CGSize(width: size.width * 0.7, height: size.height * 0.5)

        let rules: [(title: String?, image: String?, text: String?)] = [
            (
                title: "\nTurn-Based\nPlay",
                image: "card_add_1",
                text: "Each player takes turns\nplaying one card from\ntheir hand."
            ),
            (
                title: "\nTally Limit",
                image: "card_add_2",
                text: "Don't let the total\ntally go over the limit\nor you'll bust!"
            ),
            (
                title: "\nSpecial Cards",
                image: "card_add_3",
                text: "Some cards like Jinxes or\nTrumps have unique effects.\nUse them wisely!"
            ),
            (
                title: "\nElimination",
                image: "card_subtract_1",
                text: "Force opponents to bust\nto eliminate them\nfrom the round."
            ),
            (
                title: "\nVictory",
                image: "card_subtract_2",
                text: "Be the last player busting\nto win the game!"
            )
        ]


        for (i, rule) in rules.enumerated() {
            let card = RuleCardNode(
                title: rule.title,
                imageNamed: rule.image,
                text: rule.text,
                screenSize: self.size
            )
            card.position = CGPoint(x: size.width / 2, y: size.height / 2)
            card.zPosition = CGFloat(1001 + i)
            card.alpha = (i == 0) ? 1.0 : 0.0
            addChild(card)
            ruleCards.append(card)
        }
        
        // Add close button
        let buttonSize = CGSize(width: 40, height: 40)
        let close = SKSpriteNode(imageNamed: "close_icon") // Add a simple X icon to your assets
        close.name = "closeButton"
        close.size = buttonSize
        close.zPosition = 1000
        close.position = CGPoint(x: size.width - buttonSize.width - 20, y: size.height - buttonSize.height - 20)
        addChild(close)
        closeButton = close
    }
    
    func hideRuleCards() {
        touchBlockerNode?.removeFromParent()
        touchBlockerNode = nil
        isShowingRules = false

        for ruleCard in ruleCards {
            ruleCard.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
        }
        
        ruleCards.removeAll()
        
        closeButton?.removeFromParent()
        closeButton = nil
        currentRuleIndex = 0

        restorePlayedCardsToHand()
    }



//    TOUCH HANDLING
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if close button was tapped
        if let node = nodes(at: location).first(where: { $0.name == "closeButton" }) {
            hideRuleCards()
            return
        }
        
        // If rules are showing, do not allow card interaction
        guard !isShowingRules else { return }

        // Get the card that was tapped (if any)
        guard let newCard = nodes(at: location).compactMap({ $0 as? CardNode }).first else {
            // Tapped on empty space → clear selection
            selectedCard?.run(SKAction.scale(to: 1.0, duration: 0.1))
            selectedCard = nil
            dragStartLocation = nil
            lastTouchLocation = nil
            isDragging = false
            return
        }

        // Ignore interaction if card is in play or dragging
        guard !newCard.isDragging, !newCard.inPlayArea else { return }

        // Tapped the same card again → play it
        if newCard == selectedCard {
            newCard.dragging()
            dragCardToPlay(newCard)
            return
        }

        // Tapped a different card → switch selection
        selectedCard?.run(SKAction.scale(to: 1.0, duration: 0.1)) // Scale down previous

        selectedCard = newCard
        selectedCardOriginalPosition = newCard.position
        dragStartLocation = location
        lastTouchLocation = location
        isDragging = false
        selectedCard?.run(SKAction.scale(to: 1.1, duration: 0.1)) // Scale up new
    }


    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let selectedCard = selectedCard,
              let lastLocation = lastTouchLocation,
              let startLocation = dragStartLocation else { return }
        
        // 👇 Prevent dragging if the card is already in play
        if selectedCard.inPlayArea { return }

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

        playCard(selectedCard)
    }
    
    private func playCard(_ selectedCard: CardNode) {
        playedCards.append((
            node: selectedCard,
            originalPosition: selectedCardOriginalPosition ?? selectedCard.position,
            originalZPosition: selectedCard.zPosition,
            originalZRotation: selectedCard.zRotation
        ))

        if let playArea = playAreaNode {
            if playArea.frame.intersects(selectedCard.frame) {
                print("✅ Card played in hitbox area: \(selectedCard.card)")
                // Update zPosition only relative to other CardNodes
                let maxZ = (children.compactMap { $0 as? CardNode }.map(\.zPosition).max() ?? 0)
                selectedCard.zPosition = maxZ + 1

                // Snap and animate
                dragCardToPlay(selectedCard)

                // Special name behavior
                if selectedCard.name == "card_startGame" {
                    self.cardGame?.playedCardMainMenu = selectedCard
                    self.cardGame?.playedCardOriginalPositionMainMenu = selectedCardOriginalPosition

                    run(SKAction.sequence([
                        SKAction.wait(forDuration: 0.3),
                        SKAction.run { [weak self] in
                            self?.cardGame?.startMatchmaking()
                            self?.restorePlayedCardsToHand()
                        }
                    ]))
                }

                if selectedCard.name == "card_howToPlay", !isShowingRules {
                    showRuleCards()
                }

            } else {
                // Animate back if missed
                if let originalPosition = selectedCardOriginalPosition {
                    let moveBack = SKAction.move(to: originalPosition, duration: 0.25)
                    moveBack.timingMode = .easeOut
                    selectedCard.run(moveBack)
                    selectedCard.outOfPlay()
                }
                print("Card dropped outside play area")
            }
        }
    }

    
    private func dragCardToPlay(_ card: CardNode) {
        guard let playArea = playAreaNode else { return }
        let offsetX = CGFloat.random(in: -1...1)
        let offsetY = CGFloat.random(in: -5...5)
        let snapPosition = CGPoint(
            x: playArea.frame.midX + offsetX,
            y: playArea.frame.midY + offsetY
        )

        let angle = CGFloat.random(in: -15...15) * (.pi / 180)

        let move = SKAction.move(to: snapPosition, duration: 0.2)
        move.timingMode = .easeInEaseOut

        let rotate = SKAction.rotate(toAngle: angle, duration: 0.2, shortestUnitArc: true)

        let snap = SKAction.group([move, rotate])
        card.run(snap)

        card.run(SKAction.scale(to: 1.0, duration: 0.1)){
            card.stopDragging()
            card.inPlay()
        }
    }


    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !ruleCards.isEmpty else { return }

        let oldCard = ruleCards[currentRuleIndex]
        oldCard.run(SKAction.fadeOut(withDuration: 0.3))

        if gesture.direction == .left {
            currentRuleIndex = min(currentRuleIndex + 1, ruleCards.count - 1)
        } else if gesture.direction == .right {
            currentRuleIndex = max(currentRuleIndex - 1, 0)
        }

        let newCard = ruleCards[currentRuleIndex]
        newCard.run(SKAction.fadeIn(withDuration: 0.3))
    }

    
    func restorePlayedCardsToHand() {
        for played in playedCards {
            let moveBack = SKAction.move(to: played.originalPosition, duration: 0.25)
            moveBack.timingMode = .easeOut

            let rotateBack = SKAction.rotate(toAngle: played.originalZRotation, duration: 0.25, shortestUnitArc: true)
            rotateBack.timingMode = .easeOut

            let restore = SKAction.group([moveBack, rotateBack])
            played.node.run(restore)

            played.node.zPosition = played.originalZPosition
            
            played.node.outOfPlay()
        }

        playedCards.removeAll()
    }


    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CardLayoutData {
    let card: Card
    let xOffset: CGFloat
    let yOffset: CGFloat
    let zRotationDegrees: CGFloat
    let zPosition: CGFloat

    var zRotationRadians: CGFloat {
        return zRotationDegrees * (.pi / 180)
    }
}


struct MainMenuScenePreview: View {
    var scene: MainMenuScene {
        return MainMenuScene(size: UIScreen.main.bounds.size)
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}



#Preview {
    MainMenuScenePreview()
}
