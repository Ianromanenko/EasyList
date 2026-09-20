import HealthKit
import Observation

/// Быстрый старт тренировки прямо с циферблата: одно нажатие на модуль WKT,
/// без захода в «Тренировки». Пишется как обычная тренировка в Здоровье.
@MainActor
@Observable
final class WorkoutController: NSObject {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    var isActive = false
    var isPaused = false
    var startDate: Date?
    var activeEnergy: Double = 0
    var distance: Double = 0
    var heartRate: Double?
    var activity: HKWorkoutActivityType = .running

    static let quickActivities: [HKWorkoutActivityType] = [.running, .walking, .cycling, .hiking, .functionalStrengthTraining, .swimming]

    func start(_ activity: HKWorkoutActivityType) {
        guard !isActive, HKHealthStore.isHealthDataAvailable() else { return }
        self.activity = activity

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity
        configuration.locationType = activity == .swimming ? .outdoor : .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self

            let start = Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }

            self.session = session
            self.builder = builder
            self.startDate = start
            self.isActive = true
            Haptics.start()
        } catch {
            Haptics.failure()
        }
    }

    func togglePause() {
        guard let session else { return }
        if isPaused {
            session.resume()
        } else {
            session.pause()
        }
        isPaused.toggle()
        Haptics.button()
    }

    func end() {
        guard let session, let builder else { return }
        session.end()
        builder.endCollection(withEnd: Date()) { _, _ in
            builder.finishWorkout { _, _ in }
        }
        self.session = nil
        self.builder = nil
        isActive = false
        isPaused = false
        startDate = nil
        Haptics.stop()
    }

    func elapsed(at date: Date = .now) -> TimeInterval {
        guard let startDate else { return 0 }
        return date.timeIntervalSince(startDate)
    }

    static func code(for activity: HKWorkoutActivityType) -> String {
        switch activity {
        case .running: return "RUN"
        case .walking: return "WALK"
        case .cycling: return "BIKE"
        case .hiking: return "HIKE"
        case .swimming: return "SWIM"
        case .functionalStrengthTraining: return "GYM"
        default: return "WKT"
        }
    }
}

extension WorkoutController: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        let running = toState == .running
        let ended = toState == .ended
        Task { @MainActor [weak self] in
            guard let self else { return }
            if ended { self.isActive = false }
            self.isPaused = self.isActive && !running
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        Task { @MainActor [weak self] in self?.isActive = false }
    }
}

extension WorkoutController: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else { continue }

            switch quantityType.identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                let unit = HKUnit.count().unitDivided(by: .minute())
                let value = statistics.mostRecentQuantity()?.doubleValue(for: unit)
                Task { @MainActor [weak self] in self?.heartRate = value }
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor [weak self] in self?.activeEnergy = value }
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
                 HKQuantityTypeIdentifier.distanceCycling.rawValue,
                 HKQuantityTypeIdentifier.distanceSwimming.rawValue:
                let value = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                Task { @MainActor [weak self] in self?.distance = value }
            default:
                continue
            }
        }
    }
}
