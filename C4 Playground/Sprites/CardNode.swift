//
//  CardNode.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 20/06/25.
//
import SpriteKit

class CardNode: SKSpriteNode {
    let card: Card

    init(card: Card, fitToWidth: CGFloat? = nil, fitToHeight: CGFloat? = nil, preserveOriginalSize: Bool = false) {
        self.card = card
        let texture = SKTexture(imageNamed: card.imageName)

        var finalSize = texture.size()

        if !preserveOriginalSize {
            if let fitWidth = fitToWidth {
                let aspect = texture.size().height / texture.size().width
                finalSize = CGSize(width: fitWidth, height: fitWidth * aspect)
            } else if let fitHeight = fitToHeight {
                let aspect = texture.size().width / texture.size().height
                finalSize = CGSize(width: fitHeight * aspect, height: fitHeight)
            }
        }

        super.init(texture: texture, color: .clear, size: finalSize)
        self.name = card.id.uuidString
        self.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


