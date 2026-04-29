import Foundation
import CoreGraphics

final class WaveManager {
    struct WaveDefinition {
        var enemyCount: Int
        var spawnRatePerSecond: Double
        var carrierCount: Int

        init(enemyCount: Int, spawnRatePerSecond: Double, carrierCount: Int = 0) {
            self.enemyCount = max(0, enemyCount)
            self.spawnRatePerSecond = max(0.1, spawnRatePerSecond)
            self.carrierCount = max(0, min(carrierCount, enemyCount))
        }
    }

    struct SpawnRequest {
        var isCarrier: Bool
    }

    private(set) var waveIndex: Int = 0
    private var timeSinceLastSpawn: Double = 0
    private var remainingInWave: Int = 0
    private var remainingCarriersInWave: Int = 0

    var waves: [WaveDefinition]

    init(waves: [WaveDefinition] = [
        .init(enemyCount: 8, spawnRatePerSecond: 1.4, carrierCount: 1),
        .init(enemyCount: 12, spawnRatePerSecond: 1.8, carrierCount: 2),
        .init(enemyCount: 18, spawnRatePerSecond: 2.2, carrierCount: 3),
    ]) {
        self.waves = waves
        beginWaveIfNeeded()
    }

    func reset() {
        waveIndex = 0
        timeSinceLastSpawn = 0
        remainingInWave = 0
        remainingCarriersInWave = 0
        beginWaveIfNeeded()
    }

    func update(dt: TimeInterval) -> [SpawnRequest] {
        beginWaveIfNeeded()
        guard waveIndex < waves.count else { return [] }
        guard dt > 0 else { return [] }

        let wave = waves[waveIndex]
        timeSinceLastSpawn += dt

        let spawnInterval = 1.0 / wave.spawnRatePerSecond
        var spawns: [SpawnRequest] = []

        while remainingInWave > 0, timeSinceLastSpawn >= spawnInterval {
            timeSinceLastSpawn -= spawnInterval

            let shouldSpawnCarrier: Bool
            if remainingCarriersInWave <= 0 {
                shouldSpawnCarrier = false
            } else if remainingInWave == remainingCarriersInWave {
                // Force the remaining spawns to be carriers.
                shouldSpawnCarrier = true
            } else {
                // Otherwise spread carriers out randomly across the wave.
                shouldSpawnCarrier = Double.random(in: 0...1) < 0.12
            }

            if shouldSpawnCarrier {
                remainingCarriersInWave -= 1
            }

            remainingInWave -= 1
            spawns.append(.init(isCarrier: shouldSpawnCarrier))
        }

        if remainingInWave == 0 {
            // Advance once the wave has finished spawning (kill-count gating comes later).
            waveIndex += 1
            timeSinceLastSpawn = 0
            beginWaveIfNeeded()
        }

        return spawns
    }

    private func beginWaveIfNeeded() {
        guard remainingInWave == 0 else { return }
        guard waveIndex < waves.count else { return }

        let wave = waves[waveIndex]
        remainingInWave = wave.enemyCount
        remainingCarriersInWave = wave.carrierCount
    }
}

