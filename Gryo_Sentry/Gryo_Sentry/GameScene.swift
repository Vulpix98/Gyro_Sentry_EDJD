import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum GameState {
        case playing
        case gameOver
        case victory
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
    private var uiRootNode: SKNode?
    private var waveLabel: SKLabelNode?
    private var nextRoundButton: SKShapeNode?
    private var nextRoundButtonLabel: SKLabelNode?
    private var gameOverOverlay: SKShapeNode?
    private var restartButton: SKShapeNode?
    private var victoryOverlay: SKShapeNode?
    private var backToMenuButton: SKShapeNode?

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
    private let vxNullDropChance: CGFloat = 0.001
    private let playerRespawnDelay: TimeInterval = 3.0
    private let uiTopMargin: CGFloat = 90

    override func didMove(to view: SKView) {
        removeAllActions()

        backgroundColor = .black

        // If the .sks contains template nodes, remove them.
        childNode(withName: "//helloLabel")?.removeFromParent()

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupWorld()
        setupUI()
        refreshUI()
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
        guard let firstTouch = touches.first else { return }
        let location = firstTouch.location(in: self)
        // VERIFICAÇÃO DE VITÓRIA
            if gameState == .victory {
                // Usamos nodes(at:) para detectar o botão mesmo dentro do overlay
                let touchedNodes = nodes(at: location)
                for node in touchedNodes {
                    if node == backToMenuButton || node.name == "backToMenuButton" {
                        goToMainMenu()
                        return
                    }
                }
            }
        
        if gameState == .gameOver {
            if let restartButton, restartButton.contains(location) {
                restartGame()
            }
            return
        }
        if let nextRoundButton, !nextRoundButton.isHidden, nextRoundButton.contains(location) {
            _ = waveManager.startNextRound()
            refreshUI()
            return
        }
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
        refreshUI()
        checkVictoryCondition()
    }
    
    private func triggerVictory() {
        guard gameState == .playing else { return }
        gameState = .victory
        
        // Mostra o overlay
        victoryOverlay?.isHidden = false
        victoryOverlay?.zPosition = 5000
        
        // Opcional: Efeito visual no fundo
        backgroundColor = SKColor(red: 0.05, green: 0.15, blue: 0.05, alpha: 1.0)
    }
    
    private func checkVictoryCondition() {
        if waveManager.state == .complete && enemies.isEmpty {
            triggerVictory()
        }
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
        showGameOverOverlay(true)
    }

    private func updateWaves(dt: TimeInterval) {
        let spawns = waveManager.update(dt: dt)
        for spawn in spawns {
            spawnEnemy(kind: spawn.kind)
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
            let targetPosition = targetBefore?.position

            if let firedTarget = tower.updateAndFireIfReady(dt: dt, acquireTarget: nearestEnemy) {
                spawnTowerBeamEffect(from: tower.position, to: firedTarget.position)
                if wasAlive, let resolvedTarget = targetBefore, !resolvedTarget.isAlive {
                    handleEnemyDefeated(resolvedTarget, at: targetPosition ?? resolvedTarget.position)
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
        let targetPosition = target.position
        target.applyDamage(laserDamage)
        if targetWasAlive, !target.isAlive {
            handleEnemyDefeated(target, at: targetPosition)
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

    private func spawnEnemy(kind: EnemyKind, at position: CGPoint? = nil) {
        let enemy = Enemy(kind: kind, profile: EnemyProfiles.shared.profile(for: kind))
        enemy.position = randomSpawnPointOnEdge(padding: 40)
        if let position {
            enemy.position = position
        }
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
            handleEnemyDefeated(enemy, at: enemy.position)
            enemy.kill()
        } else {
            enemyBody.node?.removeFromParent()
        }
        coreNode.damage(5)
    }

    private func handlePlayerEnemyContact(enemyBody: SKPhysicsBody) {
        guard !isPlayerRespawning else { return }

        if let enemy = enemyBody.node as? Enemy {
            handleEnemyDefeated(enemy, at: enemy.position)
            enemy.kill()
        } else {
            enemyBody.node?.removeFromParent()
        }

        triggerPlayerDeath()
        playerNode.onHitEnemy()
    }

    private func handlePickupContact(pickupBody: SKPhysicsBody) {
        guard let pickup = pickupBody.node as? Pickup else {
            pickupBody.node?.removeFromParent()
            return
        }

        switch pickup.kind {
        case .tower:
            setCarryingTower(true)
        case .vxNull:
            activateVXNull()
        }
        pickup.removeFromParent()
    }

    private func handleEnemyDefeated(_ enemy: Enemy, at position: CGPoint) {
        guard gameState == .playing else { return }
        if enemy.kind == .carrier {
            // Carriers only drop tower pickups.
            guard !isCarryingTower else { return }
            guard CGFloat.random(in: 0...1) <= carrierDropChance else { return }
            spawnTowerPickup(at: position)
            spawnEnemiesFromDeath(of: enemy, at: position)
            return
        }

        // Non-carriers can drop bomb pickups.
        let bombRoll = CGFloat.random(in: 0...1)
        if bombRoll <= vxNullDropChance {
            spawnVXNullPickup(at: position)
        }

        spawnEnemiesFromDeath(of: enemy, at: position)
    }

    private func spawnEnemiesFromDeath(of enemy: Enemy, at position: CGPoint) {
        guard !enemy.profile.spawnOnDeath.isEmpty else { return }
        for rule in enemy.profile.spawnOnDeath {
            guard rule.count > 0 else { continue }
            for _ in 0..<rule.count {
                let offset = CGPoint(
                    x: CGFloat.random(in: -36...36),
                    y: CGFloat.random(in: -36...36)
                )
                spawnEnemy(
                    kind: rule.kind,
                    at: CGPoint(x: position.x + offset.x, y: position.y + offset.y)
                )
            }
        }
    }

    private func spawnTowerPickup(at position: CGPoint) {
        let pickup = Pickup(config: .init(kind: .tower))
        pickup.position = position
        addChild(pickup)
    }

    private func spawnVXNullPickup(at position: CGPoint) {
        let pickup = Pickup(config: .init(kind: .vxNull))
        pickup.position = position
        addChild(pickup)
    }

    private func activateVXNull() {
        guard gameState == .playing else { return }

        for enemy in enemies where enemy.parent != nil && enemy.isAlive {
            enemy.kill()
        }
        enemies.removeAll { $0.parent == nil || !$0.isAlive }
        spawnVXNullPulse(at: playerNode.position)
    }

    private func spawnVXNullPulse(at position: CGPoint) {
        let pulse = SKShapeNode(circleOfRadius: 14)
        pulse.position = position
        pulse.fillColor = SKColor(red: 0.72, green: 0.42, blue: 1.0, alpha: 0.35)
        pulse.strokeColor = SKColor(red: 0.82, green: 0.62, blue: 1.0, alpha: 0.95)
        pulse.lineWidth = 2
        pulse.zPosition = 1150
        addChild(pulse)

        let grow = SKAction.scale(to: 8.0, duration: 0.22)
        let fade = SKAction.fadeOut(withDuration: 0.22)
        pulse.run(.sequence([.group([grow, fade]), .removeFromParent()]))
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

    // MARK: - UI

    private func setupUI() {
            uiRootNode?.removeFromParent()

            let root = SKNode()
            root.zPosition = 4000
            addChild(root)
            uiRootNode = root

            // --- Label da Onda ---
            let wave = SKLabelNode(fontNamed: "Menlo-Bold")
            wave.fontSize = 20
            wave.horizontalAlignmentMode = .center
            wave.verticalAlignmentMode = .center
            wave.fontColor = SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
            wave.position = CGPoint(x: frame.midX, y: frame.maxY - uiTopMargin)
            root.addChild(wave)
            waveLabel = wave

            // --- Botão Próxima Ronda ---
            let startButton = SKShapeNode(rectOf: CGSize(width: 210, height: 44), cornerRadius: 10)
            startButton.fillColor = SKColor(red: 0.18, green: 0.65, blue: 1.0, alpha: 0.95)
            startButton.strokeColor = SKColor(red: 0.75, green: 0.92, blue: 1.0, alpha: 1.0)
            startButton.lineWidth = 2
            startButton.position = CGPoint(x: frame.midX, y: frame.maxY - uiTopMargin - 44)
            root.addChild(startButton)
            nextRoundButton = startButton

            let startText = SKLabelNode(fontNamed: "Menlo-Bold")
            startText.fontSize = 16
            startText.verticalAlignmentMode = .center
            startText.fontColor = .white
            startButton.addChild(startText)
            nextRoundButtonLabel = startText

            // --- Overlay de Game Over ---
            let overlay = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height))
            overlay.fillColor = SKColor(white: 0.0, alpha: 0.68)
            overlay.strokeColor = .clear
            overlay.position = CGPoint(x: frame.midX, y: frame.midY)
            overlay.zPosition = 4500
            overlay.isHidden = true
            root.addChild(overlay)
            gameOverOverlay = overlay

            let gameOverText = SKLabelNode(fontNamed: "Menlo-Bold")
            gameOverText.text = "GAME OVER"
            gameOverText.fontSize = 34
            gameOverText.fontColor = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
            gameOverText.verticalAlignmentMode = .center
            gameOverText.position = CGPoint(x: 0, y: 72)
            overlay.addChild(gameOverText)

            let restart = SKShapeNode(rectOf: CGSize(width: 190, height: 52), cornerRadius: 12)
            restart.fillColor = SKColor(red: 0.16, green: 0.56, blue: 1.0, alpha: 0.95)
            restart.strokeColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
            restart.lineWidth = 2
            restart.position = CGPoint(x: 0, y: -8)
            overlay.addChild(restart)
            restartButton = restart

            let restartText = SKLabelNode(fontNamed: "Menlo-Bold")
            restartText.text = "Restart"
            restartText.fontSize = 24
            restartText.fontColor = .white
            restartText.verticalAlignmentMode = .center
            restart.addChild(restartText)

            // --- CHAMADA PARA CRIAR A UI DE VITÓRIA ---
            // Esta é a linha que faltava para conectar tudo!
            setupVictoryUI()
        }

    private func refreshUI() {
        waveLabel?.text = waveText()
        updateNextRoundButton()
    }

    private func waveText() -> String {
        let totalRounds = max(1, waveManager.totalRounds)
        let roundNumber = min(max(1, waveManager.nextRoundIndex), totalRounds)
        return "Round \(roundNumber)/\(totalRounds)"
    }

    private func updateNextRoundButton() {
        guard let nextRoundButton, let nextRoundButtonLabel else { return }
        let canStart = gameState == .playing
            && !isPlayerRespawning
            && enemies.isEmpty
            && waveManager.state == .waitingForPlayer
            && waveManager.upcomingRoundNumber != nil

        nextRoundButton.isHidden = !canStart
        if canStart, let upcoming = waveManager.upcomingRoundNumber {
            nextRoundButtonLabel.text = "Start Round \(upcoming)"
        } else if waveManager.state == .complete {
            nextRoundButtonLabel.text = nil
        }
    }

    private func showGameOverOverlay(_ visible: Bool) {
        gameOverOverlay?.isHidden = !visible
    }

    private func restartGame() {
        removeAllActions()
        removeAllChildren()

        gameState = .playing
        backgroundColor = .black
        lastUpdateTime = 0
        activeTouch = nil
        inputVector = .zero
        keyLeft = false
        keyRight = false
        keyUp = false
        keyDown = false
        isCarryingTower = false
        isPlayerRespawning = false
        playerRespawnRemaining = 0
        enemies.removeAll()
        towers.removeAll()
        waveManager.reset()

        setupWorld()
        setupUI()
        showGameOverOverlay(false)
        refreshUI()
    }
    
    private func setupVictoryUI() {
        guard let uiRoot = uiRootNode else { return }

        // Overlay de fundo
        let overlay = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height))
        overlay.fillColor = SKColor(red: 0.0, green: 0.2, blue: 0.4, alpha: 0.8) // Azul escuro transparente
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 5000
        overlay.isHidden = true
        uiRoot.addChild(overlay)
        victoryOverlay = overlay

        let winText = SKLabelNode(fontNamed: "Menlo-Bold")
        winText.text = "MISSION COMPLETE"
        winText.fontSize = 34
        winText.fontColor = .cyan
        winText.position = CGPoint(x: 0, y: 72)
        overlay.addChild(winText)

        // Botão Voltar ao Menu
        let menuBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 52), cornerRadius: 12)
        menuBtn.fillColor = SKColor(red: 0.1, green: 0.4, blue: 0.1, alpha: 0.95) // Verde
        menuBtn.strokeColor = .white
        menuBtn.lineWidth = 2
        menuBtn.position = CGPoint(x: 0, y: -8)
        menuBtn.name = "backToMenuButton" // ADICIONE ESTA LINHA
        overlay.addChild(menuBtn)
        backToMenuButton = menuBtn

        let menuLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        menuLabel.text = "Main Menu"
        menuLabel.fontSize = 22
        menuLabel.verticalAlignmentMode = .center
        menuBtn.addChild(menuLabel)
    }
    
    // MARK: - States
    
    private func goToMainMenu() {
        // 1. Tentar carregar o ficheiro .sks do seu Menu
        if let menuScene = SKScene(fileNamed: "MainMenuScene") as? MainMenuScene {
            menuScene.size = self.size
            menuScene.scaleMode = .aspectFill
            
            let transition = SKTransition.crossFade(withDuration: 1.0)
            self.view?.presentScene(menuScene, transition: transition)
        } else {
            // Se o ficheiro .sks falhar, isto avisa-te no console
            print("Erro: Não foi possível encontrar o ficheiro MainMenuScene.sks")
            
            // Opcional: manter o plano B aqui apenas para não travar o jogo
            let fallbackMenu = MainMenuScene(size: self.size)
            fallbackMenu.scaleMode = .aspectFill
            self.view?.presentScene(fallbackMenu, transition: SKTransition.fade(withDuration: 1.0))
        }
    }
}


