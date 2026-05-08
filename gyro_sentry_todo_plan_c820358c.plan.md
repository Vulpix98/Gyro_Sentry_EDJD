---
name: Gyro Sentry TODO plan
overview: Turn the current SpriteKit template project into the Gyro Sentry MVP described in README.md (gyro-controlled drone, enemies/waves, auto-fire, tower drops/placement, core HP + game over), leaving stretch goals scoped separately.
todos:
  - id: scene-bootstrap
    content: "Replace template touch-debug logic in `Gryo_Sentry/Gryo_Sentry/GameScene.swift` with a real gameplay scene bootstrap: create core node, player drone, world bounds, and a per-frame update loop that calls motion/enemy/wave/tower systems."
    status: pending
  - id: player-drone
    content: Create `PlayerDrone.swift` with movement speed (for now controlled by a temporary keyboard/touch/joystick test input), collision handling hooks, and a basic auto-fire cadence (timer/cooldown) that requests a target from the scene. Render as a simple cube/rect with distinct colors (no final sprites yet).
    status: pending
  - id: core-base-hp
    content: Create `CoreBase.swift` representing the central core with HP, taking damage on enemy contact, and triggering a game over state when HP <= 0. Render as a simple shape with a contrasting color.
    status: pending
  - id: physics-setup
    content: Create `PhysicsCategory.swift` and set up physics bodies/bitmasks for player, enemy, pickup, core, and projectiles/lasers. Implement contact delegate in `GameScene` for pickup collection, core damage, and player-enemy collision.
    status: pending
  - id: enemy-and-waves
    content: Implement `Enemy.swift` (basic enemy + optional carrier type flag). Add `WaveManager.swift` holding an array of wave definitions (counts, spawn rate, carrier count) and spawning enemies at screen edges moving toward the core. Render enemies as colored cubes/rects for now.
    status: completed
  - id: combat-projectiles
    content: "Implement player laser/projectile or hitscan: choose simplest (hitscan with line effect or small projectile nodes). Apply damage to enemies, handle enemy death, and remove nodes cleanly."
    status: pending
  - id: tower-drop-pickup
    content: "Implement `Pickup.swift` and drop logic: carrier enemies spawn a tower pickup on death. Player collecting pickup sets `isCarryingTower = true` (or similar state) and enables placement mode."
    status: pending
  - id: tower-placement-and-behavior
    content: "Implement `Tower.swift`: tap-to-place when carrying, tower auto-targets nearest enemy within range, consumes energy over time, and self-destructs when depleted. Render towers as simple colored cubes/rects for now."
    status: pending
  - id: player-death-respawn
    content: "Implement player-enemy collision: hide/disable player, explode feedback, respawn at core after 3 seconds (cooldown), matching README behavior."
    status: pending
  - id: ui-and-game-over
    content: Add minimal UI (wave number, core HP bar/text) and a game over overlay with restart. Keep it simple with `SKLabelNode`/`SKShapeNode` (optional helper `GameUI.swift`).
    status: completed
  - id: optional-vx-null
    content: (Optional, README week 4/rare) Add a tiny probability drop for VX-Null and implement its effect as clearing all enemies safely (respecting game state).
    status: pending
  - id: motion-input
    content: "(Move to last for now) Replace the temporary test input (keyboard/touch/virtual stick) with real gyro control. Implement `MotionInput.swift` using CoreMotion (`CMMotionManager`) to provide a stable tilt vector (x/y), including smoothing (low-pass). Add calibration/zero as a stretch stub."
    status: pending
  - id: implement-sprites-final
    content: "(Last) Replace placeholder cubes/rects with final neon/retro sprites or SKShape styling pass (player, enemies, towers, pickups, core), plus any particle polish if desired."
    status: pending
isProject: false
---

# Gyro Sentry MVP Implementation Plan

## Current state (what exists)
- The project is essentially the default SpriteKit template: [`Gryo_Sentry/Gryo_Sentry/GameScene.swift`](Gryo_Sentry/Gryo_Sentry/GameScene.swift) only shows touch-driven debug shapes and an empty `update()`.
- [`Gryo_Sentry/Gryo_Sentry/GameViewController.swift`](Gryo_Sentry/Gryo_Sentry/GameViewController.swift) loads `GameScene.sks` and presents it.
- The README defines the intended gameplay loop, MVP checklist, and a 5-week milestone breakdown.

## Architecture to implement (minimal, MVP-focused)
- **Single scene**: keep gameplay inside `GameScene` for now; refactor into small types as soon as new systems appear.
- **Core entities** (SpriteKit nodes + simple logic types):
  - `PlayerDrone` (SKSpriteNode subclass or wrapper)
  - `CoreNode` (the base being defended, with HP)
  - `Enemy` (SKSpriteNode + movement toward core)
  - `Tower` (SKSpriteNode with energy + targeting)
  - `Pickup` (tower drop item the player can collect)
  - `WaveDefinition` + `WaveManager`
- **Subsystems**:
  - `MotionInput` using `CMMotionManager` (CoreMotion) -> normalized tilt vector
  - `Targeting` helper to find nearest enemy within radius
  - `Physics categories` for player/enemy/pickup/core/projectile

## File plan (expected new files)
- Add under [`Gryo_Sentry/Gryo_Sentry/`](Gryo_Sentry/Gryo_Sentry/):
  - `MotionInput.swift`
  - `PhysicsCategory.swift`
  - `PlayerDrone.swift`
  - `CoreBase.swift`
  - `Enemy.swift`
  - `WaveManager.swift`
  - `Tower.swift`
  - `Pickup.swift`
  - `GameUI.swift` (optional small helper for SKLabelNode/HP bar)
- Keep `GameScene.swift` as the orchestrator that wires these together.

## Milestone mapping (from README)
- **Week 1**: Motion + core HP + bounds clamping
- **Week 2**: Waves + enemy movement + core damage on contact
- **Week 3**: Player auto-fire + enemy health/death + tower drop pickup state
- **Week 4**: Touch to place tower + tower auto-fire + (optional) VX-Null rare drop
- **Week 5**: Player death/respawn + basic UI + game over screen

## Verification / acceptance checks (MVP)
- Drone moves smoothly via tilt (no noticeable lag), and stays within screen bounds.
- Enemies spawn at edges and reliably path to core; core loses HP on enemy contact.
- Player automatically fires at nearest enemy; enemies die with clear feedback.
- A “carrier” enemy drops a tower pickup; player can collect it and then tap to place a tower.
- Towers fire automatically until their energy expires and they self-destruct.
- Game ends when core HP reaches 0 (clear game over UI and restart flow).
