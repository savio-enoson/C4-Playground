//
//  CardNode.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 20/06/25.
//
import SpriteKit
import SwiftUI

class CardNode: SKSpriteNode {
    let card: Card
    var isFaceUp: Bool = true

    init(
        card: Card,
        fitToWidth: CGFloat? = nil,
        fitToHeight: CGFloat? = nil,
        preserveOriginalSize: Bool = false,
        _ isFaceUp: Bool = true
    ) {
        self.card = card
        self.isFaceUp = isFaceUp

        let textureName = isFaceUp ? card.imageName : "cardBack"
        let texture = SKTexture(imageNamed: textureName)

        var finalSize = texture.size()

        if !preserveOriginalSize {
            if let fitWidth = fitToWidth {
                let aspect = texture.size().height / texture.size().width
                finalSize = CGSize(width: fitWidth, height: fitWidth * aspect)
            } else {
                // Default to height-based scaling (200 if nothing provided)
                let targetHeight = fitToHeight ?? 200
                let aspect = texture.size().width / texture.size().height
                finalSize = CGSize(width: targetHeight * aspect, height: targetHeight)
            }
        }

        super.init(texture: texture, color: .clear, size: finalSize)
        self.name = card.id.uuidString
        self.isUserInteractionEnabled = false
    }
    
    func flipToFaceUp() {
        guard !isFaceUp else { return } // Already face-up
        isFaceUp = true

        let newTexture = SKTexture(imageNamed: card.imageName)

        // Optional: Flip animation
        let flip = SKAction.sequence([
            SKAction.scaleX(to: 0, duration: 0.15),
            SKAction.run { self.texture = newTexture },
            SKAction.scaleX(to: 1, duration: 0.15)
        ])

        self.run(flip)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class CardPreviewScene: SKScene {
    let card: Card
    let isFaceUp: Bool

    init(size: CGSize, card: Card, isFaceUp: Bool = false) {
        self.card = card
        self.isFaceUp = isFaceUp
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        let cardNode = CardNode(card: card, fitToHeight: 150, isFaceUp)
        cardNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cardNode)
    }
}

struct PreviewCard: View {
    var body: some View {
        SpriteView(
            scene: CardPreviewScene(
                size: CGSize(width: 200, height: 300),
                card: Card(cardType: .number, value: .add_3),
                isFaceUp: false
            )
        )
        .frame(width: 200, height: 300)
    }
}


#Preview {
    PreviewCard()
}

