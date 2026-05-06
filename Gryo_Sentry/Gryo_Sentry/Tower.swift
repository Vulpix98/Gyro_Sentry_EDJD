import SpriteKit

final class Tower: SKShapeNode {
    struct Config {
        var size: CGSize = CGSize(width: 24, height: 24)
        var cornerRadius: CGFloat = 5
        var maxEnergy: CGFloat = 12.0
        var energyDrainPerSecond: CGFloat = 1.0
        var fireCooldownSeconds: TimeInterval = 0.35
        var fireRangePoints: CGFloat = 260
        var damagePerShot: Int = 4
    }

    let config: Config
    private(set) var energy: CGFloat
    private var fireCooldownRemaining: TimeInterval = 0

    var isDepleted: Bool {
        energy <= 0
    }

    init(config: Config = Config()) {
        self.config = config
        self.energy = max(0.1, config.maxEnergy)
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

        fillColor = SKColor(red: 0.62, green: 0.35, blue: 1.0, alpha: 1.0)
        strokeColor = SKColor(red: 0.2, green: 0.1, blue: 0.35, alpha: 1.0)
        lineWidth = 1.5
        isAntialiased = true
        name = "tower"
        zPosition = 45

        let body = SKPhysicsBody(rectangleOf: config.size)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.tower
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.enemy
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func updateAndFireIfReady(
        dt: TimeInterval,
        acquireTarget: (CGPoint, CGFloat) -> Enemy?
    ) -> Enemy? {
        guard dt > 0, !isDepleted else { return nil }

        let dtf = CGFloat(dt)
        energy = max(0, energy - config.energyDrainPerSecond * dtf)
        fireCooldownRemaining = max(0, fireCooldownRemaining - dt)

        guard !isDepleted, fireCooldownRemaining == 0 else { return nil }
        guard let target = acquireTarget(position, config.fireRangePoints) else { return nil }

        target.applyDamage(config.damagePerShot)
        fireCooldownRemaining = config.fireCooldownSeconds
        return target
    }
}
