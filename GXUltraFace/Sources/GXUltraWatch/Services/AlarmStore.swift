import Foundation
import UserNotifications
import Observation

/// Будильники и часовой сигнал. У Casio это индикаторы ALARM и SIG в статусной
/// строке — здесь они не декоративные: горят ровно тогда, когда есть активные
/// уведомления, и гаснут, если система их не разрешила.
@MainActor
@Observable
final class AlarmStore {
    struct Alarm: Codable, Identifiable, Hashable {
        var id = UUID()
        var hour: Int
        var minute: Int
        var isEnabled: Bool = true
        /// Дни недели 1...7 (воскресенье = 1). Пустой набор = каждый день.
        var weekdays: Set<Int> = []
        var label: String = "ALM"

        var time: String { String(format: "%02d:%02d", hour, minute) }
    }

    private(set) var alarms: [Alarm] = []
    var notificationsAllowed = false

    private let defaults = UserDefaults.standard
    private let storageKey = "alarms.v1"

    init() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }

    var hasEnabledAlarm: Bool { alarms.contains(where: \.isEnabled) }

    var nextAlarm: (alarm: Alarm, date: Date)? {
        let calendar = Calendar.current
        return alarms
            .filter(\.isEnabled)
            .compactMap { alarm -> (Alarm, Date)? in
                var components = DateComponents()
                components.hour = alarm.hour
                components.minute = alarm.minute
                guard let date = calendar.nextDate(after: .now,
                                                   matching: components,
                                                   matchingPolicy: .nextTime) else { return nil }
                return (alarm, date)
            }
            .min { $0.1 < $1.1 }
    }

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        notificationsAllowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func add(hour: Int, minute: Int) {
        alarms.append(Alarm(hour: hour, minute: minute))
        save()
    }

    func toggle(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        save()
        Haptics.button()
    }

    func remove(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        save()
    }

    func adjust(_ alarm: Alarm, byMinutes delta: Int) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        let total = (alarms[index].hour * 60 + alarms[index].minute + delta + 1440) % 1440
        alarms[index].hour = total / 60
        alarms[index].minute = total % 60
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            defaults.set(data, forKey: storageKey)
        }
        reschedule()
    }

    private func reschedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: alarms.map { "alarm.\($0.id.uuidString)" })
        for alarm in alarms where alarm.isEnabled {
            var components = DateComponents()
            components.hour = alarm.hour
            components.minute = alarm.minute
            let content = UNMutableNotificationContent()
            content.title = "GX-ULTRA"
            content.body = "\(alarm.label) \(alarm.time)"
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: "alarm.\(alarm.id.uuidString)",
                                             content: content,
                                             trigger: trigger))
        }
    }

    // MARK: - Часовой сигнал

    /// Casio SIG: короткий сигнал каждый час. Реализован набором
    /// ежедневных уведомлений — по одному на час, поэтому работает и в фоне.
    func setHourlyChime(_ enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        let ids = (0..<24).map { "chime.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard enabled else { return }
        for hour in 0..<24 {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "GX-ULTRA"
            content.body = String(format: "%02d:00", hour)
            content.sound = nil
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: "chime.\(hour)", content: content, trigger: trigger))
        }
    }
}
