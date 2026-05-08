import SpriteKit

final class Enemy: SKShapeNode {
    struct Config {
        var size: CGSize = CGSize(width: 24, height: 24)
        var cornerRadius: CGFloat = 6
        var speedPointsPerSecond: CGFloat = 120
        var maxHP: Int = 10
        var isCarrier: Bool = false
        	
    }

    let config: Config
    private(set) var isAlive: Bool = true
    private(set) var hp: Int

    init(config: Config = Config()) {
        self.config = config
        self.hp = max(1, config.maxHP)
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

        if config.isCarrier {
            fillColor = SKColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0)
        } else {
            fillColor = SKColor(red: 0.95, green: 0.35, blue: 0.25, alpha: 1.0)
        }
        strokeColor = .clear
        isAntialiased = true
        name = config.isCarrier ? "enemy_carrier" : "enemy"

        let body = SKPhysicsBody(rectangleOf: config.size)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.linearDamping = 0
        body.friction = 0
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.core | PhysicsCategory.projectile | PhysicsCategory.tower
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func update(dt: TimeInterval, toward target: CGPoint) {
        guard isAlive, dt > 0 else { return }
        let dx = target.x - position.x
        let dy = target.y - position.y
        let len = max(0.001, sqrt(dx * dx + dy * dy))
        let nx = dx / len
        let ny = dy / len

        let dtf = CGFloat(dt)
        position.x += nx * config.speedPointsPerSecond * dtf
        position.y += ny * config.speedPointsPerSecond * dtf
    }

    func kill() {
        guard isAlive else { return }
        isAlive = false
        removeFromParent()
    }

    func applyDamage(_ amount: Int) {
        guard isAlive else { return }
        guard amount > 0 else { return }
        hp -= amount
        if hp <= 0 {
            kill()
        }
    }
}

