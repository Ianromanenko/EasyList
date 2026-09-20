import SwiftUI

/// Главный экран: строка даты, большие часы, «окно данных» и шкалы активности.
/// Каждый блок — живые данные и точка входа в соответствующий режим.
struct TimeModeView: View {
    var engine: FaceEngine
    var now: Date
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)

        VStack(spacing: 5) {
            // Верхняя строка: день недели, дата, номер недели.
            HStack(alignment: .center, spacing: 6) {
                SegmentText(text: TimeFormat.weekday(now),
                            style: .fourteen,
                            color: ink,
                            ghostOpacity: theme.ghostOpacity,
                            digitWidth: 10,
                            digitHeight: 15,
                            spacing: 1.5,
                            weight: 0.2,
                            showsGhosts: false)

                SegmentText(text: TimeFormat.dayMonth(now),
                            style: .seven,
                            color: ink,
                            ghostOpacity: theme.ghostOpacity,
                            digitWidth: 10,
                            digitHeight: 15,
                            spacing: 1.5,
                            weight: 0.2,
                            showsGhosts: false)

                Spacer(minLength: 0)

                LCDLabel("WK\(TimeFormat.weekOfYear(now))", color: ink, size: 10, opacity: 0.6)

                if !engine.settings.use24h {
                    LCDLabel(TimeFormat.isPM(now) ? "PM" : "AM", color: theme.accent, size: 10, opacity: 1)
                }
            }
            .padding(.horizontal, 8)

            // Основное время. Секунды — отдельным мелким блоком справа,
            // как у Casio; в always-on они прячутся.
            HStack(alignment: .top, spacing: 4) {
                BigReadout(text: TimeFormat.hhmm(now, use24h: engine.settings.use24h),
                           theme: theme,
                           isDimmed: isDimmed,
                           digitWidth: 33,
                           digitHeight: 52)
                .layoutPriority(1)

                if engine.settings.showSeconds && !isDimmed {
                    SegmentText(text: TimeFormat.seconds(now),
                                style: .seven,
                                color: theme.accent,
                                ghostOpacity: theme.ghostOpacity,
                                digitWidth: 13,
                                digitHeight: 20,
                                spacing: 1.5,
                                weight: 0.2)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)

            // Окно данных — переключается кнопкой DATA или тапом по нему.
            HStack(spacing: 8) {
                DataCell(label: engine.settings.pinnedReadout.code,
                         value: readoutValue,
                         unit: readoutUnit,
                         theme: theme,
                         isDimmed: isDimmed,
                         accented: engine.settings.pinnedReadout == .heartRate) {
                    cycleReadout()
                }

                DataCell(label: "MOVE",
                         value: String(Int(engine.health.activeEnergy)),
                         unit: "KCAL",
                         theme: theme,
                         isDimmed: isDimmed) {
                    engine.select(.vitals)
                }
            }
            .padding(.horizontal, 8)

            // Три шкалы активности вместо колец — читаются боковым зрением.
            if !isDimmed {
                VStack(spacing: 3) {
                    activityRow("MOV", engine.health.moveRatio, theme)
                    activityRow("EXE", engine.health.exerciseRatio, theme)
                    activityRow("STD", engine.health.standRatio, theme)
                }
                .padding(.horizontal, 8)
                .onTapGesture { engine.select(.vitals) }
            }
        }
    }

    private func activityRow(_ label: String, _ value: Double, _ theme: FaceTheme) -> some View {
        HStack(spacing: 5) {
            LCDLabel(label, color: theme.ink(dimmed: isDimmed), size: 9, opacity: 0.55)
                .frame(width: 24, alignment: .leading)
            SegmentBar(value: value,
                       cells: 14,
                       color: theme.ink(dimmed: isDimmed),
                       ghostOpacity: theme.ghostOpacity,
                       cellHeight: 5,
                       spacing: 1.5,
                       overflowColor: theme.accent)
        }
    }

    private func cycleReadout() {
        let all = FaceSettings.Readout.allCases
        let index = all.firstIndex(of: engine.settings.pinnedReadout) ?? 0
        engine.settings.pinnedReadout = all[(index + 1) % all.count]
        Haptics.button()
    }

    private var readoutValue: String {
        switch engine.settings.pinnedReadout {
        case .heartRate:
            return engine.health.heartRate.map { String(Int($0)) } ?? "---"
        case .steps:
            return String(max(engine.health.steps, engine.motion.currentSteps))
        case .altitude:
            let altitude = engine.motion.absoluteAltitude ?? engine.location.altitudeGPS
            return altitude.map { String(Int($0)) } ?? "----"
        case .temperature:
            return engine.weather.temperature.map { String(Int($0.rounded())) } ?? "--"
        case .battery:
            return String(engine.battery.percent)
        case .calories:
            return String(Int(engine.health.activeEnergy))
        }
    }

    private var readoutUnit: String? {
        switch engine.settings.pinnedReadout {
        case .heartRate: return "BPM"
        case .steps: return "STP"
        case .altitude: return "M"
        case .temperature: return "°C"
        case .battery: return "%"
        case .calories: return "KCAL"
        }
    }
}
