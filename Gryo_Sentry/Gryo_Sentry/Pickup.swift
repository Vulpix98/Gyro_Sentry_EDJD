import SpriteKit

final class Pickup: SKShapeNode {
    struct Config {
        var size: CGSize = CGSize(width: 18, height: 18)
        var cornerRadius: CGFloat = 4
    }

    private(set) var config: Config

    init(config: Config = Config()) {
        self.config = config
        super.init()

        path = CGPath(
            roundedRect: CGRect(
                x: -config.size.width / 2,
                y: -config.size.height / 2,
                width: config.size.width,
                height: config.size.height
            ),
            cornerWidth: config.cornerRadius,
            cornerHeight: config.cornerRadius,
            transform: nil
        )

        fillColor = SKColor(red: 0.35, green: 0.98, blue: 0.45, alpha: 1.0)
        strokeColor = SKColor(red: 0.15, green: 0.45, blue: 0.15, alpha: 1.0)
        lineWidth = 1.5
        isAntialiased = true
        name = "tower_pickup"
        zPosition = 40

        let body = SKPhysicsBody(rectangleOf: config.size)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.pickup
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body

        let pulseUp = SKAction.scale(to: 1.08, duration: 0.45)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.95, duration: 0.45)
        pulseDown.timingMode = .easeInEaseOut
        run(.repeatForever(.sequence([pulseUp, pulseDown])))
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
