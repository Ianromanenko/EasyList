import Foundation

/// Быстрое форматирование без DateFormatter: экран обновляется раз в секунду,
/// а формат-объекты на каждом кадре — это лишние миллисекунды и джоули.
enum TimeFormat {
    static let weekdayCodes = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    static let monthCodes = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                             "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

    static func components(_ date: Date, timeZone: TimeZone = .current) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second,
                                        .weekday, .weekOfYear], from: date)
    }

    static func hhmm(_ date: Date, timeZone: TimeZone = .current, use24h: Bool = true) -> String {
        let c = components(date, timeZone: timeZone)
        var hour = c.hour ?? 0
        if !use24h {
            hour = hour % 12
            if hour == 0 { hour = 12 }
        }
        return String(format: "%02d:%02d", hour, c.minute ?? 0)
    }

    static func seconds(_ date: Date, timeZone: TimeZone = .current) -> String {
        String(format: "%02d", components(date, timeZone: timeZone).second ?? 0)
    }

    static func hhmmss(_ date: Date, timeZone: TimeZone = .current, use24h: Bool = true) -> String {
        hhmm(date, timeZone: timeZone, use24h: use24h) + ":" + seconds(date, timeZone: timeZone)
    }

    static func weekday(_ date: Date, timeZone: TimeZone = .current) -> String {
        let index = (components(date, timeZone: timeZone).weekday ?? 1) - 1
        return weekdayCodes[max(0, min(index, 6))]
    }

    static func month(_ date: Date, timeZone: TimeZone = .current) -> String {
        let index = (components(date, timeZone: timeZone).month ?? 1) - 1
        return monthCodes[max(0, min(index, 11))]
    }

    /// Casio показывает дату как «9-15»: месяц-день.
    static func dayMonth(_ date: Date, timeZone: TimeZone = .current) -> String {
        let c = components(date, timeZone: timeZone)
        return String(format: "%d-%02d", c.month ?? 1, c.day ?? 1)
    }

    static func weekOfYear(_ date: Date, timeZone: TimeZone = .current) -> Int {
        components(date, timeZone: timeZone).weekOfYear ?? 0
    }

    static func isPM(_ date: Date, timeZone: TimeZone = .current) -> Bool {
        (components(date, timeZone: timeZone).hour ?? 0) >= 12
    }

    /// Разница с домашним поясом: «+2H» / «-5H» — как в модуле WORLD TIME.
    static func offsetCode(_ timeZone: TimeZone, from home: TimeZone = .current, at date: Date = .now) -> String {
        let delta = (timeZone.secondsFromGMT(for: date) - home.secondsFromGMT(for: date)) / 3600
        return delta == 0 ? "SAME" : String(format: "%+dH", delta)
    }

    /// Код города для 14-сегментной строки: «Europe/Kyiv» → «KYIV».
    static func cityCode(_ timeZone: TimeZone) -> String {
        let city = timeZone.identifier.split(separator: "/").last.map(String.init) ?? timeZone.identifier
        let cleaned = city.replacingOccurrences(of: "_", with: " ").uppercased()
        return String(cleaned.prefix(6))
    }

    /// «5H 42M» — компактная длительность для восхода/заката и таймеров.
    static func duration(_ interval: TimeInterval) -> String {
        let total = Int(max(interval, 0))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? String(format: "%dH %02dM", hours, minutes) : String(format: "%dM", minutes)
    }
}
