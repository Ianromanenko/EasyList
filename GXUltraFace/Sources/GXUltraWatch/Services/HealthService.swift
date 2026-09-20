import HealthKit
import Observation

/// Живые данные Здоровья для LCD: пульс, кольца, шаги, HRV.
/// Пульс тянем anchored-запросом — значение обновляется само, без поллинга.
@MainActor
@Observable
final class HealthService {
    private let store = HKHealthStore()

    var heartRate: Double?
    var heartRateSamples: [Double] = []      // последний час, для гистограммы
    var restingHeartRate: Double?
    var hrv: Double?
    var steps: Int = 0
    var distanceMeters: Double = 0
    var activeEnergy: Double = 0
    var exerciseMinutes: Double = 0
    var standHours: Int = 0
    var moveGoal: Double = 500
    var exerciseGoal: Double = 30
    var standGoal: Double = 12
    var isAuthorized = false

    private var runningQueries: [HKQuery] = []

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.activitySummaryType()]
        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
            .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .appleExerciseTime
        ]
        for id in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: id) { types.insert(type) }
        }
        return types
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        do {
            try await store.requestAuthorization(toShare: share, read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        observeHeartRate()
        refreshSummaries()
        refreshDailyTotals()
    }

    func stop() {
        runningQueries.forEach { store.stop($0) }
        runningQueries.removeAll()
    }

    // MARK: - Пульс

    private func observeHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let start = Date().addingTimeInterval(-3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil, options: .strictEndDate)

        let handler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] _, samples, _, _, _ in
            guard let quantities = samples as? [HKQuantitySample], !quantities.isEmpty else { return }
            let unit = HKUnit.count().unitDivided(by: .minute())
            let values = quantities.map { $0.quantity.doubleValue(for: unit) }
            let latest = quantities.max(by: { $0.endDate < $1.endDate })?.quantity.doubleValue(for: unit)
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let latest { self.heartRate = latest }
                self.heartRateSamples.append(contentsOf: values)
                if self.heartRateSamples.count > 240 {
                    self.heartRateSamples.removeFirst(self.heartRateSamples.count - 240)
                }
            }
        }

        let query = HKAnchoredObjectQuery(type: type,
                                          predicate: predicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: handler)
        query.updateHandler = handler
        store.execute(query)
        runningQueries.append(query)

        latestValue(for: .restingHeartRate, unit: .count().unitDivided(by: .minute())) { [weak self] value in
            self?.restingHeartRate = value
        }
        latestValue(for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) { [weak self] value in
            self?.hrv = value
        }
    }

    private func latestValue(for identifier: HKQuantityTypeIdentifier,
                             unit: HKUnit,
                             completion: @escaping @MainActor (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
            Task { @MainActor in completion(value) }
        }
        store.execute(query)
    }

    // MARK: - Кольца и дневные суммы

    func refreshSummaries() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.calendar = calendar
        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let query = HKActivitySummaryQuery(predicate: predicate) { [weak self] _, summaries, _ in
            guard let summary = summaries?.first else { return }
            let energy = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
            let energyGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
            let exercise = summary.appleExerciseTime.doubleValue(for: .minute())
            let exerciseGoal = summary.exerciseTimeGoal.doubleValue(for: .minute())
            let stand = summary.appleStandHours.doubleValue(for: .count())
            let standGoal = summary.standHoursGoal.doubleValue(for: .count())
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.activeEnergy = energy
                self.moveGoal = max(energyGoal, 1)
                self.exerciseMinutes = exercise
                self.exerciseGoal = max(exerciseGoal, 1)
                self.standHours = Int(stand)
                self.standGoal = max(standGoal, 1)
            }
        }
        store.execute(query)
        runningQueries.append(query)
    }

    func refreshDailyTotals() {
        sumToday(.stepCount, unit: .count()) { [weak self] value in
            self?.steps = Int(value ?? 0)
        }
        sumToday(.distanceWalkingRunning, unit: .meter()) { [weak self] value in
            self?.distanceMeters = value ?? 0
        }
    }

    private func sumToday(_ identifier: HKQuantityTypeIdentifier,
                          unit: HKUnit,
                          completion: @escaping @MainActor (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, statistics, _ in
            let value = statistics?.sumQuantity()?.doubleValue(for: unit)
            Task { @MainActor in completion(value) }
        }
        store.execute(query)
    }

    // MARK: - Производные

    var moveRatio: Double { activeEnergy / moveGoal }
    var exerciseRatio: Double { exerciseMinutes / exerciseGoal }
    var standRatio: Double { Double(standHours) / standGoal }

    /// Нагрузка по отношению к покою — быстрый ответ «я сейчас в норме?».
    var strainIndex: Double? {
        guard let heartRate, let restingHeartRate, restingHeartRate > 0 else { return nil }
        return heartRate / restingHeartRate
    }
}
