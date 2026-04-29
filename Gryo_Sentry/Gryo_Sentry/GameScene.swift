import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum GameState {
        case playing
        case gameOver
    }

    private var gameState: GameState = .playing

    // MARK: - World nodes (placeholder visuals: colored cubes/rects)
    private var coreNode: CoreBase!
    private var playerNode: PlayerDrone!
    private var enemies: [Enemy] = []
    private let waveManager = WaveManager()

    // MARK: - Simulation
    private var lastUpdateTime: TimeInterval = 0

    // Temporary test input (touch “virtual stick”).
    private var activeTouch: UITouch?
    private var inputVector: CGVector = .zero

    // Temporary keyboard input (arrow keys). Works in Simulator / with hardware keyboard.
    private var keyLeft = false
    private var keyRight = false
    private var keyUp = false
    private var keyDown = false

    // Tunables
    private let worldMargin: CGFloat = 16
    private let laserDamage: Int = 3

    override func didMove(to view: SKView) {
        removeAllActions()

        backgroundColor = .black

        // If the .sks contains template nodes, remove them.
        childNode(withName: "//helloLabel")?.removeFromParent()

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupWorld()
    }

    private func setupWorld() {
        // Core (center)
        let core = CoreBase()
        core.position = CGPoint(x: frame.midX, y: frame.midY)
        core.onDepleted = { [weak self] in
            self?.triggerGameOver()
        }
        addChild(core)
        coreNode = core

        // Player (starts at the core)
        let player = PlayerDrone()
        player.position = core.position
        player.onFire = { [weak self] range in
            self?.playerAutofire(range: range)
        }
        addChild(player)
        playerNode = player
    }

    // MARK: - Input (temporary)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        if activeTouch == nil, let t = touches.first {
            activeTouch = t
            updateInput(from: t.location(in: self))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        guard let activeTouch else { return }
        if touches.contains(activeTouch) {
            updateInput(from: activeTouch.location(in: self))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch else { return }
        if touches.contains(activeTouch) {
            self.activeTouch = nil
            inputVector = .zero
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func updateInput(from touchPosition: CGPoint) {
        // “Virtual stick”: vector from player -> touch, clamped to unit length.
        let dx = touchPosition.x - playerNode.position.x
        let dy = touchPosition.y - playerNode.position.y
        let len = max(CGFloat(1), sqrt(dx * dx + dy * dy))
        let nx = dx / len
        let ny = dy / len
        inputVector = CGVector(dx: nx, dy: ny)
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }

        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        updateInputVectorFromKeyboardIfTouchIsInactive()
        playerNode.update(dt: dt, input: inputVector, clamp: clampToWorld)

        // Stubs for upcoming systems (enemies, waves, towers, combat, UI).
        // These will become real once we implement the corresponding TODOs.
        updateWaves(dt: dt)
        updateEnemies(dt: dt)
        updateTowers(dt: dt)
    }

    private func clampToWorld(_ position: CGPoint, _ node: SKNode) -> CGPoint {
        let halfW = node.frame.width / 2
        let halfH = node.frame.height / 2
        let minX = frame.minX + worldMargin + halfW
        let maxX = frame.maxX - worldMargin - halfW
        let minY = frame.minY + worldMargin + halfH
        let maxY = frame.maxY - worldMargin - halfH

        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }

    private func updateInputVectorFromKeyboardIfTouchIsInactive() {
        // Touch “virtual stick” overrides keyboard.
        if activeTouch != nil { return }

        var x: CGFloat = 0
        var y: CGFloat = 0
        if keyLeft { x -= 1 }
        if keyRight { x += 1 }
        if keyUp { y += 1 }
        if keyDown { y -= 1 }

        // Normalize diagonal movement.
        let len = max(1, sqrt(x * x + y * y))
        inputVector = CGVector(dx: x / len, dy: y / len)
    }

    // MARK: - Keyboard hooks (called by GameViewController)

    func setArrowKey(_ key: ArrowKey, isDown: Bool) {
        switch key {
        case .left: keyLeft = isDown
        case .right: keyRight = isDown
        case .up: keyUp = isDown
        case .down: keyDown = isDown
        }
    }

    enum ArrowKey {
        case left, right, up, down
    }

    // MARK: - Debug hooks

    func debugDamageCore() {
        coreNode.damage(10)
    }

    func debugHealCore() {
        coreNode.heal(10)
    }

    private func triggerGameOver() {
        guard gameState != .gameOver else { return }
        gameState = .gameOver

        // Light red background on game over.
        backgroundColor = SKColor(red: 0.35, green: 0.05, blue: 0.08, alpha: 1.0)
    }

    private func updateWaves(dt: TimeInterval) {
        let spawns = waveManager.update(dt: dt)
        for spawn in spawns {
            spawnEnemy(isCarrier: spawn.isCarrier)
        }
    }

    private func updateEnemies(dt: TimeInterval) {
        let target = coreNode.position
        for enemy in enemies {
            enemy.update(dt: dt, toward: target)
        }

        enemies.removeAll { $0.parent == nil }
    }

    private func updateTowers(dt: TimeInterval) {
        _ = dt
    }

    private func playerAutofire(range: CGFloat) {
        guard let target = nearestEnemy(to: playerNode.position, maxRange: range) else { return }
        target.applyDamage(laserDamage)
        spawnLaserEffect(from: playerNode.position, to: target.position)
    }

    private func nearestEnemy(to origin: CGPoint, maxRange: CGFloat) -> Enemy? {
        let maxR2 = maxRange * maxRange
        var best: Enemy?
        var bestD2: CGFloat = .greatestFiniteMagnitude

        for enemy in enemies where enemy.parent != nil && enemy.isAlive {
            let dx = enemy.position.x - origin.x
            let dy = enemy.position.y - origin.y
            let d2 = dx * dx + dy * dy
            if d2 <= maxR2, d2 < bestD2 {
                best = enemy
                bestD2 = d2
            }
        }

        return best
    }

    private func spawnLaserEffect(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(red: 0.35, green: 1.0, blue: 0.9, alpha: 0.95)
        line.lineWidth = 3
        line.glowWidth = 6
        line.zPosition = 1000
        addChild(line)

        let fade = SKAction.fadeOut(withDuration: 0.08)
        let remove = SKAction.removeFromParent()
        line.run(.sequence([fade, remove]))
    }

    private func spawnEnemy(isCarrier: Bool) {
        let enemy = Enemy(config: .init(isCarrier: isCarrier))
        enemy.position = randomSpawnPointOnEdge(padding: 40)
        addChild(enemy)
        enemies.append(enemy)
    }

    private func randomSpawnPointOnEdge(padding: CGFloat) -> CGPoint {
        let minX = frame.minX + padding
        let maxX = frame.maxX - padding
        let minY = frame.minY + padding
        let maxY = frame.maxY - padding

        let side = Int.random(in: 0..<4)
        switch side {
        case 0: // left
            return CGPoint(x: frame.minX - padding, y: CGFloat.random(in: minY...maxY))
        case 1: // right
            return CGPoint(x: frame.maxX + padding, y: CGFloat.random(in: minY...maxY))
        case 2: // bottom
            return CGPoint(x: CGFloat.random(in: minX...maxX), y: frame.minY - padding)
        default: // top
            return CGPoint(x: CGFloat.random(in: minX...maxX), y: frame.maxY + padding)
        }
    }

    // MARK: - Physics contacts

    func didBegin(_ contact: SKPhysicsContact) {
        guard gameState == .playing else { return }

        let a = contact.bodyA
        let b = contact.bodyB

        let mask = a.categoryBitMask | b.categoryBitMask

        if mask == (PhysicsCategory.core | PhysicsCategory.enemy) {
            let coreBody = (a.categoryBitMask == PhysicsCategory.core) ? a : b
            let enemyBody = (a.categoryBitMask == PhysicsCategory.enemy) ? a : b
            handleCoreEnemyContact(coreBody: coreBody, enemyBody: enemyBody)
            return
        }

        if mask == (PhysicsCategory.player | PhysicsCategory.enemy) {
            let enemyBody = (a.categoryBitMask == PhysicsCategory.enemy) ? a : b
            handlePlayerEnemyContact(enemyBody: enemyBody)
            return
        }

        if mask == (PhysicsCategory.player | PhysicsCategory.pickup) {
            handlePickupContact(pickupBody: (a.categoryBitMask == PhysicsCategory.pickup) ? a : b)
            return
        }
    }

    private func handleCoreEnemyContact(coreBody: SKPhysicsBody, enemyBody: SKPhysicsBody) {
        _ = coreBody
        enemyBody.node?.removeFromParent()
        coreNode.damage(5)
    }

    private func handlePlayerEnemyContact(enemyBody: SKPhysicsBody) {
        // TODO: Implement “player death/respawn” TODO later; for now just provide a hook.
        enemyBody.node?.removeFromParent()
        playerNode.onHitEnemy()
    }

    private func handlePickupContact(pickupBody: SKPhysicsBody) {
        // TODO: Once `Pickup.swift` exists, set “carrying tower” state and remove pickup.
        pickupBody.node?.removeFromParent()
    }
}
