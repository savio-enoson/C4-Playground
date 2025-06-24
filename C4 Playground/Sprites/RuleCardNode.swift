import Foundation
import SpriteKit

class RuleCardNode: SKSpriteNode {
    init(
        card: String = "blue",
        title: String? = nil,
        imageNamed: String? = nil,
        text: String? = nil,
        screenSize: CGSize
    ) {
        // Determine size with preserved aspect ratio
        let targetHeight = min(screenSize.height * 0.8, screenSize.width * 0.8)
        let texture = SKTexture(imageNamed: card)
        let aspectRatio = texture.size().width / texture.size().height
        let targetSize = CGSize(width: targetHeight * aspectRatio, height: targetHeight)

        super.init(texture: texture, color: .clear, size: targetSize)
        self.zPosition = 100

        let verticalPadding: CGFloat = targetSize.height * 0.05
        let contentNode = SKNode()
        contentNode.position = CGPoint(x: 0, y: targetSize.height / 2 - verticalPadding)
        addChild(contentNode)

        var currentYOffset: CGFloat = 0

        // TITLE
        if let title = title {
            let lines = title.components(separatedBy: "\n")
            let fontSize = targetSize.height * 0.075
            for line in lines {
                let titleLabel = SKLabelNode(text: line)
                titleLabel.fontName = "AvenirNext-Bold"
                titleLabel.fontSize = fontSize
                titleLabel.fontColor = .white
                titleLabel.horizontalAlignmentMode = .center
                titleLabel.verticalAlignmentMode = .center
                titleLabel.position = CGPoint(x: 0, y: currentYOffset)
                contentNode.addChild(titleLabel)
                currentYOffset -= fontSize + 6
            }
            currentYOffset -= verticalPadding
        }

        // IMAGE
        if let imageName = imageNamed {
            let imageTexture = SKTexture(imageNamed: imageName)
            let imageAspect = imageTexture.size().width / imageTexture.size().height
            let imageHeight = targetSize.height * 0.25
            let imageNode = SKSpriteNode(texture: imageTexture)
            imageNode.size = CGSize(width: imageHeight * imageAspect, height: imageHeight)
            imageNode.position = CGPoint(x: 0, y: currentYOffset - imageNode.size.height / 2)
            contentNode.addChild(imageNode)
            currentYOffset -= imageNode.size.height + verticalPadding
        }

        // TEXT
        if let text = text {
            let lines = text.components(separatedBy: "\n")
            let fontSize = targetSize.height * 0.05
            for line in lines {
                let textLabel = SKLabelNode(text: line)
                textLabel.fontName = "AvenirNext-Regular"
                textLabel.fontSize = fontSize
                textLabel.fontColor = .white
                textLabel.horizontalAlignmentMode = .center
                textLabel.verticalAlignmentMode = .center
                textLabel.position = CGPoint(x: 0, y: currentYOffset)
                contentNode.addChild(textLabel)
                currentYOffset -= fontSize + 4
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
