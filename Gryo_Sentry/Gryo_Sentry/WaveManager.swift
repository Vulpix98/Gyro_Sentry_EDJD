import Foundation
import CoreGraphics

final class WaveManager {
    struct RoundDefinition: Decodable {
        var round: Int
        var enemyCount: Int
        var carrierCount: Int
        var initialSpawnRatePerSecond: Double
        var spawnRateIncreasePerSecond: Double

        func normalized(index: Int) -> RoundDefinition {
            .init(
                round: max(1, round == 0 ? index + 1 : round),
                enemyCount: max(0, enemyCount),
                carrierCount: max(0, min(carrierCount, max(0, enemyCount))),
                initialSpawnRatePerSecond: max(0.1, initialSpawnRatePerSecond),
                spawnRateIncreasePerSecond: max(0.0, spawnRateIncreasePerSecond)
            )
        }
    }

    struct SpawnRequest {
        var isCarrier: Bool
    }

    enum State {
        case waitingForPlayer
        case spawning
        case complete
    }

    private(set) var state: State = .waitingForPlayer
    private(set) var nextRoundIndex: Int = 0
    private(set) var activeRoundIndex: Int?
    private var timeSinceLastSpawn: Double = 0
    private var elapsedInRound: Double = 0
    private var remainingInRound: Int = 0
    private var remainingCarriersInRound: Int = 0

    let rounds: [RoundDefinition]

    var totalRounds: Int { rounds.count }
    var activeRoundNumber: Int? { activeRoundIndex.map { rounds[$0].round } }
    var upcomingRoundNumber: Int? {
        guard nextRoundIndex < rounds.count else { return nil }
        return rounds[nextRoundIndex].round
    }

    init(rounds: [RoundDefinition] = WaveManager.loadRoundDefinitions()) {
        self.rounds = rounds.enumerated().map { index, round in
            round.normalized(index: index)
        }
    }

    func reset() {
        state = .waitingForPlayer
        nextRoundIndex = 0
        activeRoundIndex = nil
        timeSinceLastSpawn = 0
        elapsedInRound = 0
        remainingInRound = 0
        remainingCarriersInRound = 0
    }

    @discardableResult
    func startNextRound() -> Bool {
        guard state == .waitingForPlayer else { return false }
        guard nextRoundIndex < rounds.count else {
            state = .complete
            return false
        }

        let round = rounds[nextRoundIndex]
        activeRoundIndex = nextRoundIndex
        nextRoundIndex += 1
        timeSinceLastSpawn = 0
        elapsedInRound = 0
        remainingInRound = round.enemyCount
        remainingCarriersInRound = round.carrierCount
        state = .spawning
        return true
    }

    func update(dt: TimeInterval) -> [SpawnRequest] {
        guard state == .spawning else { return [] }
        guard let currentActiveRoundIndex = activeRoundIndex else { return [] }
        guard dt > 0 else { return [] }

        let round = rounds[currentActiveRoundIndex]
        timeSinceLastSpawn += dt
        elapsedInRound += dt

        let currentRate = round.initialSpawnRatePerSecond + (round.spawnRateIncreasePerSecond * elapsedInRound)
        let spawnInterval = 1.0 / max(0.1, currentRate)
        var spawns: [SpawnRequest] = []

        while remainingInRound > 0, timeSinceLastSpawn >= spawnInterval {
            timeSinceLastSpawn -= spawnInterval

            let shouldSpawnCarrier: Bool
            if remainingCarriersInRound <= 0 {
                shouldSpawnCarrier = false
            } else if remainingInRound == remainingCarriersInRound {
                // Force the remaining spawns to be carriers.
                shouldSpawnCarrier = true
            } else {
                // Distribute carriers evenly over remaining spawns.
                let p = Double(remainingCarriersInRound) / Double(max(1, remainingInRound))
                shouldSpawnCarrier = Double.random(in: 0...1) < p
            }

            if shouldSpawnCarrier {
                remainingCarriersInRound -= 1
            }

            remainingInRound -= 1
            spawns.append(.init(isCarrier: shouldSpawnCarrier))
        }

        if remainingInRound == 0 {
            activeRoundIndex = nil
            timeSinceLastSpawn = 0
            elapsedInRound = 0
            state = nextRoundIndex < rounds.count ? .waitingForPlayer : .complete
        }

        return spawns
    }

    private static func loadRoundDefinitions() -> [RoundDefinition] {
        guard
            let url = Bundle.main.url(forResource: "WaveRounds", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([RoundDefinition].self, from: data),
            !decoded.isEmpty
        else {
            return [
                .init(round: 1, enemyCount: 5, carrierCount: 1, initialSpawnRatePerSecond: 0.9, spawnRateIncreasePerSecond: 0.12),
                .init(round: 2, enemyCount: 8, carrierCount: 2, initialSpawnRatePerSecond: 1.1, spawnRateIncreasePerSecond: 0.16),
                .init(round: 3, enemyCount: 12, carrierCount: 3, initialSpawnRatePerSecond: 1.3, spawnRateIncreasePerSecond: 0.22),
            ]
        }

        return decoded
    }
}

