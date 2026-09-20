import Foundation

/// Снимок данных для осложнений. Приложение пишет его в общий App Group,
/// виджет читает — так на штатных циферблатах Apple появляются те же
/// LCD-модули, что и в GX-ULTRA, без второго запроса к HealthKit.
struct FaceSnapshot: Codable, Sendable {
    var themeID: String = FaceTheme.negative.rawValue
    var heartRate: Int?
    var steps: Int?
    var batteryPercent: Int?
    var altitude: Int?
    var temperature: Int?
    var movePercent: Int?
    var nextAlarm: String?
    var stopwatchRunning: Bool = false
    var updated: Date = .now

    var theme: FaceTheme { FaceTheme(rawValue: themeID) ?? .negative }

    static let suiteName = "group.com.easylist.gxultra"
    private static let key = "face.snapshot"

    static func load() -> FaceSnapshot {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(FaceSnapshot.self, from: data) else {
            return FaceSnapshot()
        }
        return snapshot
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.suiteName),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
