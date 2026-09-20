import SwiftUI

/// Палитры LCD. Каждая имитирует конкретный тип дисплея Casio.
enum FaceTheme: String, CaseIterable, Identifiable, Sendable {
    /// DW-5600: классический позитивный STN — тёмные сегменты на сером поле.
    case dw5600
    /// GW-M5610 "negative": светлые сегменты на чёрном.
    case negative
    /// Mudmaster: оливковая подложка, янтарные сегменты.
    case mudmaster
    /// Frogman: сине-зелёный дайверский LCD.
    case frogman
    /// Ночной режим Ultra Wayfinder: только красный, чтобы не сбивать адаптацию глаза.
    case nightRed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dw5600: return "DW-5600"
        case .negative: return "NEGATIVE"
        case .mudmaster: return "MUDMASTER"
        case .frogman: return "FROGMAN"
        case .nightRed: return "NIGHT"
        }
    }

    /// Подложка LCD (то, что видно сквозь выключенные сегменты).
    var glass: Color {
        switch self {
        case .dw5600: return Color(red: 0.62, green: 0.66, blue: 0.60)
        case .negative: return Color(red: 0.04, green: 0.05, blue: 0.05)
        case .mudmaster: return Color(red: 0.24, green: 0.25, blue: 0.18)
        case .frogman: return Color(red: 0.05, green: 0.12, blue: 0.13)
        case .nightRed: return Color(red: 0.03, green: 0.0, blue: 0.0)
        }
    }

    /// Включённый сегмент.
    var ink: Color {
        switch self {
        case .dw5600: return Color(red: 0.08, green: 0.10, blue: 0.09)
        case .negative: return Color(red: 0.78, green: 0.88, blue: 0.82)
        case .mudmaster: return Color(red: 0.98, green: 0.76, blue: 0.30)
        case .frogman: return Color(red: 0.36, green: 0.94, blue: 0.80)
        case .nightRed: return Color(red: 1.0, green: 0.15, blue: 0.10)
        }
    }

    /// Акцент — им подсвечиваются активные модули, рекорды, тревоги.
    var accent: Color {
        switch self {
        case .dw5600: return Color(red: 0.85, green: 0.35, blue: 0.10)
        case .negative: return Color(red: 1.0, green: 0.62, blue: 0.0)
        case .mudmaster: return Color(red: 0.55, green: 0.85, blue: 0.35)
        case .frogman: return Color(red: 1.0, green: 0.52, blue: 0.16)
        case .nightRed: return Color(red: 1.0, green: 0.42, blue: 0.30)
        }
    }

    /// Цвет EL-подсветки (заливка стекла при тапе).
    var backlight: Color {
        switch self {
        case .dw5600: return Color(red: 0.45, green: 0.95, blue: 0.70)
        case .negative: return Color(red: 0.15, green: 0.55, blue: 0.45)
        case .mudmaster: return Color(red: 0.95, green: 0.65, blue: 0.20)
        case .frogman: return Color(red: 0.25, green: 0.85, blue: 0.95)
        case .nightRed: return Color(red: 0.75, green: 0.08, blue: 0.05)
        }
    }

    /// Непрозрачность "призрачных" (выключенных) сегментов — главный признак живого LCD.
    var ghostOpacity: Double {
        switch self {
        case .dw5600: return 0.13
        case .negative: return 0.10
        case .mudmaster: return 0.12
        case .frogman: return 0.11
        case .nightRed: return 0.07
        }
    }

    /// В always-on кадре яркость режется, чтобы не выжигать OLED.
    func ink(dimmed: Bool) -> Color { dimmed ? ink.opacity(0.55) : ink }
}
