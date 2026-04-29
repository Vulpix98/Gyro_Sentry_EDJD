import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private enum GameState {
        case playing
        case gameOver
    }

    private var gameState: GameState = .playing

    // MARK: - World nodes (placeholder visuals: colored cubes/rects)
    private var coreNode: CoreBase!
    private var playerNode: PlayerDrone!

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

    override func didMove(to view: SKView) {
        removeAllActions()

        backgroundColor = .black

        // If the .sks contains template nodes, remove them.
        childNode(withName: "//helloLabel")?.removeFromParent()

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
        _ = dt
    }

    private func updateEnemies(dt: TimeInterval) {
        _ = dt
    }

    private func updateTowers(dt: TimeInterval) {
        _ = dt
    }
}
