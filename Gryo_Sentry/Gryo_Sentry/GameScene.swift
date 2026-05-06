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
    private var towers: [Tower] = []
    private var isCarryingTower = false
    private var carryIndicatorNode: SKShapeNode?
    private var isPlayerRespawning = false
    private var playerRespawnRemaining: TimeInterval = 0
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
    private let towerPlacementMargin: CGFloat = 28
    private let carrierDropChance: CGFloat = 1.0
    private let playerRespawnDelay: TimeInterval = 3.0

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

        let indicatorSize = CGSize(width: 36, height: 36)
        let indicator = SKShapeNode(
            rectOf: indicatorSize,
            cornerRadius: 8
        )
        indicator.strokeColor = SKColor(red: 0.25, green: 1.0, blue: 0.35, alpha: 0.95)
        indicator.lineWidth = 2
        indicator.fillColor = .clear
        indicator.zPosition = 60
        indicator.isHidden = true
        player.addChild(indicator)
        carryIndicatorNode = indicator
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
        if isPlayerRespawning {
            updatePlayerRespawnTimer(dt: dt)
        } else {
            playerNode.update(dt: dt, input: inputVector, clamp: clampToWorld)
        }

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

    func placeTowerIfCarrying() {
        guard gameState == .playing else { return }
        guard !isPlayerRespawning else { return }
        guard isCarryingTower else { return }

        let tower = Tower()
        tower.position = clampTowerPosition(playerNode.position, tower: tower)
        addChild(tower)
        towers.append(tower)
        setCarryingTower(false)
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
        for tower in towers where tower.parent != nil {
            let targetBefore = nearestEnemy(to: tower.position, maxRange: tower.config.fireRangePoints)
            let wasAlive = targetBefore?.isAlive ?? false
            let wasCarrier = targetBefore?.config.isCarrier ?? false
            let targetPosition = targetBefore?.position

            if let firedTarget = tower.updateAndFireIfReady(dt: dt, acquireTarget: nearestEnemy) {
                spawnTowerBeamEffect(from: tower.position, to: firedTarget.position)
                if wasAlive, let resolvedTarget = targetBefore, !resolvedTarget.isAlive {
                    handleEnemyDefeated(at: targetPosition ?? resolvedTarget.position, wasCarrier: wasCarrier)
                }
            }

            if tower.isDepleted {
                tower.removeFromParent()
            }
        }

        towers.removeAll { $0.parent == nil }
    }

    private func playerAutofire(range: CGFloat) {
        guard let target = nearestEnemy(to: playerNode.position, maxRange: range) else { return }
        let targetWasAlive = target.isAlive
        let targetWasCarrier = target.config.isCarrier
        let targetPosition = target.position
        target.applyDamage(laserDamage)
        if targetWasAlive, !target.isAlive {
            handleEnemyDefeated(at: targetPosition, wasCarrier: targetWasCarrier)
        }
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

    private func spawnTowerBeamEffect(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(red: 0.75, green: 0.45, blue: 1.0, alpha: 0.95)
        line.lineWidth = 2
        line.glowWidth = 5
        line.zPosition = 950
        addChild(line)

        let fade = SKAction.fadeOut(withDuration: 0.1)
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
        if let enemy = enemyBody.node as? Enemy {
            handleEnemyDefeated(at: enemy.position, wasCarrier: enemy.config.isCarrier)
            enemy.kill()
        } else {
            enemyBody.node?.removeFromParent()
        }
        coreNode.damage(5)
    }

    private func handlePlayerEnemyContact(enemyBody: SKPhysicsBody) {
        guard !isPlayerRespawning else { return }

        if let enemy = enemyBody.node as? Enemy {
            handleEnemyDefeated(at: enemy.position, wasCarrier: enemy.config.isCarrier)
            enemy.kill()
        } else {
            enemyBody.node?.removeFromParent()
        }

        triggerPlayerDeath()
        playerNode.onHitEnemy()
    }

    private func handlePickupContact(pickupBody: SKPhysicsBody) {
        setCarryingTower(true)
        pickupBody.node?.removeFromParent()
    }

    private func handleEnemyDefeated(at position: CGPoint, wasCarrier: Bool) {
        guard wasCarrier else { return }
        guard !isCarryingTower else { return }
        guard CGFloat.random(in: 0...1) <= carrierDropChance else { return }
        spawnTowerPickup(at: position)
    }

    private func spawnTowerPickup(at position: CGPoint) {
        let pickup = Pickup()
        pickup.position = position
        addChild(pickup)
    }

    private func setCarryingTower(_ carrying: Bool) {
        isCarryingTower = carrying
        carryIndicatorNode?.isHidden = !carrying
    }

    private func triggerPlayerDeath() {
        guard !isPlayerRespawning else { return }
        let deathPosition = playerNode.position
        isPlayerRespawning = true
        playerRespawnRemaining = playerRespawnDelay
        playerNode.deactivateForRespawn()
        spawnPlayerExplosion(at: deathPosition)
    }

    private func updatePlayerRespawnTimer(dt: TimeInterval) {
        guard dt > 0 else { return }
        playerRespawnRemaining = max(0, playerRespawnRemaining - dt)
        if playerRespawnRemaining == 0 {
            isPlayerRespawning = false
            playerNode.respawn(at: coreNode.position)
        }
    }

    private func spawnPlayerExplosion(at position: CGPoint) {
        let blast = SKShapeNode(circleOfRadius: 10)
        blast.position = position
        blast.fillColor = SKColor(red: 0.15, green: 0.95, blue: 1.0, alpha: 0.85)
        blast.strokeColor = SKColor(red: 0.8, green: 1.0, blue: 1.0, alpha: 1.0)
        blast.lineWidth = 2
        blast.zPosition = 1200
        addChild(blast)

        let grow = SKAction.scale(to: 2.8, duration: 0.18)
        let fade = SKAction.fadeOut(withDuration: 0.18)
        let remove = SKAction.removeFromParent()
        blast.run(.sequence([.group([grow, fade]), remove]))
    }

    private func clampTowerPosition(_ position: CGPoint, tower: Tower) -> CGPoint {
        let halfW = tower.frame.width / 2
        let halfH = tower.frame.height / 2
        let minX = frame.minX + towerPlacementMargin + halfW
        let maxX = frame.maxX - towerPlacementMargin - halfW
        let minY = frame.minY + towerPlacementMargin + halfH
        let maxY = frame.maxY - towerPlacementMargin - halfH
        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }
}
