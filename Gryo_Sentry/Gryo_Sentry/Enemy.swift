import SpriteKit
import Foundation

enum EnemyKind: String, Codable, CaseIterable {
    case normal
    case carrier
    case speed
    case boss
    case tank
}

struct EnemySpawnOnDeath: Codable {
    var kind: EnemyKind
    var count: Int
}

struct EnemyProfile: Codable {
    var kind: EnemyKind
    var maxHP: Int
    var speedPointsPerSecond: CGFloat
    var scale: CGFloat
    var colorHex: String
    var spawnOnDeath: [EnemySpawnOnDeath]

    func normalized() -> EnemyProfile {
        EnemyProfile(
            kind: kind,
            maxHP: max(1, maxHP),
            speedPointsPerSecond: max(1, speedPointsPerSecond),
            scale: max(0.25, scale),
            colorHex: colorHex,
            spawnOnDeath: spawnOnDeath.filter { $0.count > 0 }
        )
    }
}

final class EnemyProfiles {
    static let shared = EnemyProfiles()

    private let profilesByKind: [EnemyKind: EnemyProfile]

    private init() {
        let loaded = Self.loadProfiles()
        var map: [EnemyKind: EnemyProfile] = [:]
        for profile in loaded {
            map[profile.kind] = profile.normalized()
        }
        profilesByKind = map
    }

    func profile(for kind: EnemyKind) -> EnemyProfile {
        profilesByKind[kind] ?? Self.fallbackProfiles()[kind]!
    }

    private static func loadProfiles() -> [EnemyProfile] {
        guard
            let url = Bundle.main.url(forResource: "EnemyProfiles", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([EnemyProfile].self, from: data),
            !decoded.isEmpty
        else {
            return Array(fallbackProfiles().values)
        }
        return decoded
    }

    private static func fallbackProfiles() -> [EnemyKind: EnemyProfile] {
        [
            .normal: EnemyProfile(kind: .normal, maxHP: 10, speedPointsPerSecond: 120, scale: 1.0, colorHex: "#F25940", spawnOnDeath: []),
            .carrier: EnemyProfile(kind: .carrier, maxHP: 14, speedPointsPerSecond: 105, scale: 1.1, colorHex: "#FFB84D", spawnOnDeath: []),
            .speed: EnemyProfile(kind: .speed, maxHP: 6, speedPointsPerSecond: 190, scale: 0.85, colorHex: "#40D8F7", spawnOnDeath: []),
            .boss: EnemyProfile(kind: .boss, maxHP: 75, speedPointsPerSecond: 75, scale: 1.7, colorHex: "#C53DFF", spawnOnDeath: [
                EnemySpawnOnDeath(kind: .normal, count: 3),
                EnemySpawnOnDeath(kind: .speed, count: 2),
            ]),
            .tank: EnemyProfile(kind: .tank, maxHP: 36, speedPointsPerSecond: 70, scale: 1.35, colorHex: "#7D8796", spawnOnDeath: []),
        ]
    }
}

final class Enemy: SKShapeNode {
    private let baseSize: CGFloat = 24
    let kind: EnemyKind
    let profile: EnemyProfile
    private(set) var isAlive: Bool = true
    private(set) var hp: Int

    init(kind: EnemyKind, profile: EnemyProfile) {
        self.kind = kind
        self.profile = profile
        self.hp = max(1, profile.maxHP)
        super.init()

        let size = CGSize(width: baseSize, height: baseSize)
        path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: 6,
            cornerHeight: 6,
            transform: nil
        )

        fillColor = SKColor(hex: profile.colorHex)
        strokeColor = .clear
        isAntialiased = true
        name = "enemy_\(kind.rawValue)"
        setScale(profile.scale)

        let body = SKPhysicsBody(rectangleOf: size)
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
        position.x += nx * profile.speedPointsPerSecond * dtf
        position.y += ny * profile.speedPointsPerSecond * dtf
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

private extension SKColor {
    convenience init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        if sanitized.count != 6 {
            self.init(red: 1, green: 0, blue: 1, alpha: 1)
            return
        }

        var value: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&value) else {
            self.init(red: 1, green: 0, blue: 1, alpha: 1)
            return
        }

        let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

