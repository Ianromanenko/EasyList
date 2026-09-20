import Foundation
import UserNotifications
import Observation

/// Обратный отсчёт с пресетами (как TIMER на Casio: 1/3/5/10/25 мин)
/// и локальным уведомлением, чтобы сработало даже с погашенным экраном.
@MainActor
@Observable
final class TimerEngine {
    static let presets: [TimeInterval] = [60, 180, 300, 600, 1500, 3600]

    private(set) var fireDate: Date?
    private(set) var remainingWhenPaused: TimeInterval?
    var duration: TimeInterval = 300
    var repeats = false

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let fire = "timer.fire"
        static let duration = "timer.duration"
        static let paused = "timer.paused"
    }

    init() {
        fireDate = defaults.object(forKey: Keys.fire) as? Date
        duration = defaults.object(forKey: Keys.duration) as? TimeInterval ?? 300
        remainingWhenPaused = defaults.object(forKey: Keys.paused) as? TimeInterval
    }

    var isRunning: Bool { fireDate != nil }

    func remaining(at date: Date = .now) -> TimeInterval {
        if let fireDate { return max(fireDate.timeIntervalSince(date), 0) }
        return remainingWhenPaused ?? duration
    }

    func progress(at date: Date = .now) -> Double {
        guard duration > 0 else { return 0 }
        return 1 - remaining(at: date) / duration
    }

    func start() {
        let interval = remainingWhenPaused ?? duration
        fireDate = Date.now.addingTimeInterval(interval)
        remainingWhenPaused = nil
        persist()
        scheduleNotification(after: interval)
        Haptics.start()
    }

    func pause() {
        guard let fireDate else { return }
        remainingWhenPaused = max(fireDate.timeIntervalSinceNow, 0)
        self.fireDate = nil
        persist()
        cancelNotification()
        Haptics.stop()
    }

    func toggle() { isRunning ? pause() : start() }

    func reset() {
        fireDate = nil
        remainingWhenPaused = nil
        persist()
        cancelNotification()
        Haptics.button()
    }

    func setDuration(_ value: TimeInterval) {
        duration = max(value, 1)
        if !isRunning { remainingWhenPaused = nil }
        persist()
    }

    /// Вызывается из вью, когда отсчёт дошёл до нуля.
    func handleFired() {
        guard isRunning, remaining() <= 0 else { return }
        Haptics.alarm()
        if repeats {
            fireDate = Date.now.addingTimeInterval(duration)
            scheduleNotification(after: duration)
        } else {
            fireDate = nil
            remainingWhenPaused = nil
        }
        persist()
    }

    private func persist() {
        defaults.set(fireDate, forKey: Keys.fire)
        defaults.set(duration, forKey: Keys.duration)
        defaults.set(remainingWhenPaused, forKey: Keys.paused)
    }

    private func scheduleNotification(after interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "GX-ULTRA"
        content.body = "Таймер \(StopwatchEngine.format(duration, showsHundredths: false)) вышел"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: false)
        let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }

    private static let notificationID = "gxultra.timer"
}
