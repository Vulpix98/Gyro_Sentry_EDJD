import Foundation
import CoreGraphics

final class WaveManager {
    struct EnemyMix: Decodable {
        var normal: Int
        var carrier: Int
        var speed: Int
        var boss: Int
        var tank: Int

        func normalized() -> EnemyMix {
            EnemyMix(
                normal: max(0, normal),
                carrier: max(0, carrier),
                speed: max(0, speed),
                boss: max(0, boss),
                tank: max(0, tank)
            )
        }

        var totalCount: Int {
            max(0, normal) + max(0, carrier) + max(0, speed) + max(0, boss) + max(0, tank)
        }

        func asRemainingMap() -> [EnemyKind: Int] {
            [
                .normal: max(0, normal),
                .carrier: max(0, carrier),
                .speed: max(0, speed),
                .boss: max(0, boss),
                .tank: max(0, tank),
            ]
        }
    }

    struct RoundDefinition: Decodable {
        var round: Int
        var enemies: EnemyMix
        var initialSpawnRatePerSecond: Double
        var spawnRateIncreasePerSecond: Double

        func normalized(index: Int) -> RoundDefinition {
            .init(
                round: max(1, round == 0 ? index + 1 : round),
                enemies: enemies.normalized(),
                initialSpawnRatePerSecond: max(0.1, initialSpawnRatePerSecond),
                spawnRateIncreasePerSecond: max(0.0, spawnRateIncreasePerSecond)
            )
        }
    }

    struct SpawnRequest {
        var kind: EnemyKind
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
    private var remainingByKind: [EnemyKind: Int] = [:]

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
        remainingByKind = [:]
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
        remainingInRound = round.enemies.totalCount
        remainingByKind = round.enemies.asRemainingMap()
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

            guard let nextKind = pickNextKind() else {
                remainingInRound = 0
                break
            }

            remainingInRound -= 1
            spawns.append(.init(kind: nextKind))
        }

        if remainingInRound == 0 {
            activeRoundIndex = nil
            timeSinceLastSpawn = 0
            elapsedInRound = 0
            remainingByKind = [:]
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
                .init(round: 1, enemies: .init(normal: 3, carrier: 1, speed: 1, boss: 0, tank: 0), initialSpawnRatePerSecond: 0.9, spawnRateIncreasePerSecond: 0.12),
                .init(round: 2, enemies: .init(normal: 4, carrier: 1, speed: 2, boss: 0, tank: 1), initialSpawnRatePerSecond: 1.1, spawnRateIncreasePerSecond: 0.16),
                .init(round: 3, enemies: .init(normal: 6, carrier: 2, speed: 2, boss: 1, tank: 1), initialSpawnRatePerSecond: 1.3, spawnRateIncreasePerSecond: 0.22),
            ]
        }

        return decoded
    }

    private func pickNextKind() -> EnemyKind? {
        let totalRemaining = remainingByKind.values.reduce(0, +)
        guard totalRemaining > 0 else { return nil }

        var roll = Int.random(in: 0..<totalRemaining)
        for kind in EnemyKind.allCases {
            let count = remainingByKind[kind, default: 0]
            if count <= 0 { continue }
            if roll < count {
                remainingByKind[kind] = count - 1
                return kind
            }
            roll -= count
        }
        return nil
    }
}

