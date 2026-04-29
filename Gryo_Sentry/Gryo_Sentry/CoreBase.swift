import SpriteKit

final class CoreBase: SKNode {
    struct Config {
        var maxHP: Int = 100
        var startHP: Int = 100
        var size: CGSize = CGSize(width: 56, height: 56)
        var cornerRadius: CGFloat = 10

        // UI bar
        var barSize: CGSize = CGSize(width: 140, height: 12)
        var barOffset: CGPoint = CGPoint(x: 0, y: 54)
    }

    private let config: Config

    private let bodyNode: SKShapeNode
    private let barBackground: SKShapeNode
    private let barFill: SKSpriteNode

    private(set) var hp: Int {
        didSet { updateBar() }
    }
    let maxHP: Int
    var onDepleted: (() -> Void)?

    init(config: Config = Config()) {
        self.config = config
        self.maxHP = max(1, config.maxHP)
        self.hp = min(max(0, config.startHP), max(1, config.maxHP))

        bodyNode = SKShapeNode(rectOf: config.size, cornerRadius: config.cornerRadius)
        bodyNode.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.65, alpha: 1.0)
        bodyNode.strokeColor = .clear

        barBackground = SKShapeNode(rectOf: config.barSize, cornerRadius: config.barSize.height / 2)
        barBackground.fillColor = SKColor(white: 1.0, alpha: 0.12)
        barBackground.strokeColor = .clear

        // Use SKSpriteNode so scaling happens from a true left anchor.
        barFill = SKSpriteNode(color: SKColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 1.0), size: config.barSize)
        barFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        barFill.position = CGPoint(x: -config.barSize.width / 2, y: 0)
        barFill.xScale = 1.0

        super.init()

        name = "core"

        addChild(bodyNode)

        let barContainer = SKNode()
        barContainer.position = config.barOffset
        addChild(barContainer)

        barContainer.addChild(barBackground)
        barContainer.addChild(barFill)

        let body = SKPhysicsBody(rectangleOf: config.size)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.core
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.player
        physicsBody = body

        updateBar()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func damage(_ amount: Int) {
        guard amount > 0 else { return }
        setHP(hp - amount)
    }

    func heal(_ amount: Int) {
        guard amount > 0 else { return }
        setHP(hp + amount)
    }

    func setHP(_ newValue: Int) {
        let previous = hp
        hp = min(max(0, newValue), maxHP)

        if previous > 0, hp <= 0 {
            onDepleted?()
        }
    }

    private func updateBar() {
        let ratio = CGFloat(hp) / CGFloat(maxHP)
        barFill.xScale = max(0, min(1, ratio))

        // Color shift for visibility (green -> yellow -> red)
        if ratio > 0.5 {
            barFill.color = SKColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 1.0)
        } else if ratio > 0.25 {
            barFill.color = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
        } else {
            barFill.color = SKColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
        }
    }
}

