import SpriteKit

final class PlayerDrone: SKShapeNode {
    struct Config {
        var size: CGSize = CGSize(width: 28, height: 28)
        var cornerRadius: CGFloat = 6
        var speedPointsPerSecond: CGFloat = 420
        var fireCooldownSeconds: TimeInterval = 0.18
        var fireRangePoints: CGFloat = 180
    }

    private(set) var config: Config
    private var fireCooldownRemaining: TimeInterval = 0
    private var gameplayEnabled = true
    var onFire: ((CGFloat) -> Void)?

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

        fillColor = SKColor(red: 0.1, green: 0.85, blue: 1.0, alpha: 1.0)
        strokeColor = .clear
        isAntialiased = true
        name = "player"

        let body = SKPhysicsBody(rectangleOf: config.size)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.linearDamping = 0
        body.friction = 0
        body.restitution = 0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.pickup | PhysicsCategory.core
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func update(
        dt: TimeInterval,
        input: CGVector,
        clamp: (CGPoint, SKNode) -> CGPoint
    ) {
        guard gameplayEnabled else { return }
        guard dt > 0 else { return }

        move(dt: dt, input: input, clamp: clamp)
        tickAutofire(dt: dt)
    }

    // MARK: - Collision hooks (stubs for now)

    func onHitEnemy() {
        // TODO: used later for “player dies on collision” mechanics.
    }

    func deactivateForRespawn() {
        gameplayEnabled = false
        isHidden = true
        fireCooldownRemaining = 0
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.none
    }

    func respawn(at position: CGPoint) {
        self.position = position
        gameplayEnabled = true
        isHidden = false
        fireCooldownRemaining = 0
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.pickup | PhysicsCategory.core
    }

    // MARK: - Auto-fire (cadence stub)

    private func tickAutofire(dt: TimeInterval) {
        fireCooldownRemaining = max(0, fireCooldownRemaining - dt)
        if fireCooldownRemaining == 0 {
            onFire?(config.fireRangePoints)
            fireCooldownRemaining = config.fireCooldownSeconds
        }
    }

    private func move(
        dt: TimeInterval,
        input: CGVector,
        clamp: (CGPoint, SKNode) -> CGPoint
    ) {
        let dtf = CGFloat(dt)
        let vx = input.dx * config.speedPointsPerSecond
        let vy = input.dy * config.speedPointsPerSecond

        var next = position
        next.x += vx * dtf
        next.y += vy * dtf
        position = clamp(next, self)
    }
}

