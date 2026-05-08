import SpriteKit

final class Pickup: SKShapeNode {
    enum Kind {
        case tower
        case vxNull
    }

    struct Config {
        var size: CGSize = CGSize(width: 18, height: 18)
        var cornerRadius: CGFloat = 4
        var kind: Kind = .tower
    }

    private(set) var config: Config
    var kind: Kind { config.kind }

    init(config: Config = Config()) {
        self.config = config
        super.init()

        let cornerRadius: CGFloat
        switch config.kind {
        case .tower:
            cornerRadius = config.cornerRadius
        case .vxNull:
            cornerRadius = 0
        }
        path = CGPath(
            roundedRect: CGRect(
                x: -config.size.width / 2,
                y: -config.size.height / 2,
                width: config.size.width,
                height: config.size.height
            ),
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        switch config.kind {
        case .tower:
            fillColor = SKColor(red: 0.70, green: 0.35, blue: 1.0, alpha: 1.0)
            strokeColor = SKColor(red: 0.35, green: 0.15, blue: 0.50, alpha: 1.0)
            name = "tower_pickup"
        case .vxNull:
            fillColor = SKColor(white: 1.0, alpha: 1.0)
            strokeColor = SKColor(white: 0.78, alpha: 1.0)
            name = "vx_null_pickup"
        }
        lineWidth = 1.5
        isAntialiased = true
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
