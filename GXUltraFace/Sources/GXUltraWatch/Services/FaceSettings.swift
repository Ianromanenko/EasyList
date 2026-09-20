import SwiftUI
import Observation

/// Всё, что пользователь настраивает «отвёрткой» (кнопка ADJUST) и что должно пережить перезапуск.
@MainActor
@Observable
final class FaceSettings {
    static let shared = FaceSettings()

    private let defaults: UserDefaults

    /// App Group нужен, чтобы осложнения (виджеты) видели те же настройки.
    init(suiteName: String? = "group.com.easylist.gxultra") {
        self.defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        self.theme = FaceTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .negative
        self.use24h = defaults.object(forKey: Keys.use24h) as? Bool ?? true
        self.showSeconds = defaults.object(forKey: Keys.showSeconds) as? Bool ?? true
        self.hourlyChime = defaults.bool(forKey: Keys.chime)
        self.backlightSeconds = defaults.object(forKey: Keys.backlight) as? Double ?? 3
        self.dualTimeZoneID = defaults.string(forKey: Keys.dualTZ) ?? "Europe/Kyiv"
        self.pinnedReadout = Readout(rawValue: defaults.string(forKey: Keys.readout) ?? "") ?? .heartRate
        self.crownSwitchesMode = defaults.object(forKey: Keys.crown) as? Bool ?? true
    }

    var theme: FaceTheme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    var use24h: Bool { didSet { defaults.set(use24h, forKey: Keys.use24h) } }
    var showSeconds: Bool { didSet { defaults.set(showSeconds, forKey: Keys.showSeconds) } }
    var hourlyChime: Bool { didSet { defaults.set(hourlyChime, forKey: Keys.chime) } }
    var backlightSeconds: Double { didSet { defaults.set(backlightSeconds, forKey: Keys.backlight) } }
    var dualTimeZoneID: String { didSet { defaults.set(dualTimeZoneID, forKey: Keys.dualTZ) } }
    var pinnedReadout: Readout { didSet { defaults.set(pinnedReadout.rawValue, forKey: Keys.readout) } }
    var crownSwitchesMode: Bool { didSet { defaults.set(crownSwitchesMode, forKey: Keys.crown) } }

    var dualTimeZone: TimeZone { TimeZone(identifier: dualTimeZoneID) ?? .current }

    /// Что показывать в правом верхнем окне в режиме TIME.
    enum Readout: String, CaseIterable, Identifiable {
        case heartRate, steps, altitude, temperature, battery, calories

        var id: String { rawValue }

        var code: String {
            switch self {
            case .heartRate: return "HR"
            case .steps: return "STEP"
            case .altitude: return "ALTI"
            case .temperature: return "TEMP"
            case .battery: return "BATT"
            case .calories: return "KCAL"
            }
        }
    }

    private enum Keys {
        static let theme = "face.theme"
        static let use24h = "face.use24h"
        static let showSeconds = "face.showSeconds"
        static let chime = "face.chime"
        static let backlight = "face.backlight"
        static let dualTZ = "face.dualTZ"
        static let readout = "face.readout"
        static let crown = "face.crown"
    }
}
