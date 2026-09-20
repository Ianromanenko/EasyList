import SwiftUI

/// Режимы модуля — то, что на Casio перебирается кнопкой MODE.
/// Здесь их перебирает колёсико Digital Crown или свайп.
enum FaceMode: String, CaseIterable, Identifiable, Sendable {
    case time       // основной циферблат
    case vitals     // пульс, HRV, кольца
    case stopwatch
    case timer
    case alarm
    case dual       // второй часовой пояс
    case sun        // восход/закат/луна
    case compass
    case baro       // высота + давление
    case dive       // глубина/температура воды (Ultra)
    case workout

    var id: String { rawValue }

    /// Код в 14-сегментной строке статуса.
    var code: String {
        switch self {
        case .time: return "TIME"
        case .vitals: return "BPM"
        case .stopwatch: return "STW"
        case .timer: return "TMR"
        case .alarm: return "ALM"
        case .dual: return "DUAL"
        case .sun: return "SUN"
        case .compass: return "CMP"
        case .baro: return "ALTI"
        case .dive: return "DIVE"
        case .workout: return "WKT"
        }
    }

    var title: String {
        switch self {
        case .time: return "Время"
        case .vitals: return "Пульс и активность"
        case .stopwatch: return "Секундомер"
        case .timer: return "Таймер"
        case .alarm: return "Будильники"
        case .dual: return "Второй пояс"
        case .sun: return "Солнце и луна"
        case .compass: return "Компас"
        case .baro: return "Высота и давление"
        case .dive: return "Глубина"
        case .workout: return "Тренировка"
        }
    }
}

/// Нижний ряд «кнопок корпуса». Подписи меняются под режим —
/// как надписи вокруг кнопок на реальном G-Shock.
struct SoftKey: Identifiable {
    let id = UUID()
    var label: String
    var isAccented: Bool = false
    var action: () -> Void
}
