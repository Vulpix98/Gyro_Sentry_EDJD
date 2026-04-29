import CoreMotion
import Foundation

final class MotionInput {
    struct Output {
        var x: Double
        var y: Double
    }

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    // Low-pass filtered output
    private var filteredX: Double = 0
    private var filteredY: Double = 0

    // Calibration offset (simple “zero”)
    private var zeroX: Double = 0
    private var zeroY: Double = 0

    // Tunables
    var updateInterval: TimeInterval = 1.0 / 60.0
    var lowPassAlpha: Double = 0.18

    private(set) var latest: Output = .init(x: 0, y: 0)

    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable || motionManager.isAccelerometerAvailable
    }

    func start() {
        queue.qualityOfService = .userInteractive

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
                guard let self, let motion else { return }

                // Tilt proxy: gravity vector. Keep it simple and stable.
                let gx = motion.gravity.x
                let gy = motion.gravity.y
                self.ingest(rawX: gx, rawY: gy)
            }
            return
        }

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = updateInterval
            motionManager.startAccelerometerUpdates(to: queue) { [weak self] accel, _ in
                guard let self, let accel else { return }
                self.ingest(rawX: accel.acceleration.x, rawY: accel.acceleration.y)
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    func calibrateZero() {
        zeroX = filteredX
        zeroY = filteredY
    }

    private func ingest(rawX: Double, rawY: Double) {
        let ax = max(0.0, min(1.0, lowPassAlpha))
        filteredX = filteredX + ax * (rawX - filteredX)
        filteredY = filteredY + ax * (rawY - filteredY)

        latest = Output(x: filteredX - zeroX, y: filteredY - zeroY)
    }
}
