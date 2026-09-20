import Foundation
import Observation

/// Секундомер с кругами. Время считается от абсолютной метки, поэтому
/// переживает сон экрана, фон и перезапуск приложения.
@MainActor
@Observable
final class StopwatchEngine {
    private(set) var startDate: Date?
    private(set) var accumulated: TimeInterval = 0
    private(set) var laps: [TimeInterval] = []

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let start = "stopwatch.start"
        static let accumulated = "stopwatch.accumulated"
        static let laps = "stopwatch.laps"
    }

    init() {
        if let start = defaults.object(forKey: Keys.start) as? Date { startDate = start }
        accumulated = defaults.double(forKey: Keys.accumulated)
        laps = defaults.array(forKey: Keys.laps) as? [TimeInterval] ?? []
    }

    var isRunning: Bool { startDate != nil }

    func elapsed(at date: Date = .now) -> TimeInterval {
        guard let startDate else { return accumulated }
        return accumulated + date.timeIntervalSince(startDate)
    }

    func toggle() {
        if isRunning { pause() } else { start() }
    }

    func start() {
        guard !isRunning else { return }
        startDate = .now
        persist()
        Haptics.start()
    }

    func pause() {
        guard let startDate else { return }
        accumulated += Date.now.timeIntervalSince(startDate)
        self.startDate = nil
        persist()
        Haptics.stop()
    }

    func reset() {
        startDate = nil
        accumulated = 0
        laps = []
        persist()
        Haptics.button()
    }

    /// Круг. Второй тап по LAP на остановленном секундомере сбрасывает — как на Casio.
    func lap() {
        guard isRunning else { reset(); return }
        laps.insert(elapsed(), at: 0)
        if laps.count > 50 { laps.removeLast() }
        persist()
        Haptics.lap()
    }

    /// Разница между последними кругами — видно, ускоряешься или нет.
    var lastSplit: TimeInterval? {
        guard laps.count >= 2 else { return laps.first }
        return laps[0] - laps[1]
    }

    private func persist() {
        defaults.set(startDate, forKey: Keys.start)
        defaults.set(accumulated, forKey: Keys.accumulated)
        defaults.set(laps, forKey: Keys.laps)
    }

    /// Формат 00:00'00"0 — как на модуле Casio.
    static func format(_ interval: TimeInterval, showsHundredths: Bool = true) -> String {
        let total = max(interval, 0)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let seconds = Int(total) % 60
        let hundredths = Int((total - floor(total)) * 100)
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return showsHundredths
            ? String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}
