import SwiftUI

/// Второй часовой пояс — модуль WORLD TIME. Домашнее время остаётся сверху,
/// чтобы не путаться: видно оба и разницу между ними.
struct DualTimeModeView: View {
    var engine: FaceEngine
    var now: Date
    var isDimmed: Bool

    /// Города «на кнопке»: перебираются тапом, как список DST-городов у Casio.
    static let cities = ["Europe/Kyiv", "Europe/Warsaw", "Europe/Berlin", "Europe/London",
                         "America/Toronto", "America/New_York", "America/Los_Angeles",
                         "Asia/Tokyo", "Asia/Dubai", "Australia/Sydney", "UTC"]

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let zone = engine.settings.dualTimeZone

        VStack(spacing: 6) {
            VStack(spacing: 1) {
                SegmentText(text: TimeFormat.cityCode(zone),
                            style: .fourteen,
                            color: theme.accent,
                            ghostOpacity: theme.ghostOpacity,
                            digitWidth: 13,
                            digitHeight: 19,
                            spacing: 1.5,
                            weight: 0.2,
                            showsGhosts: false)

                BigReadout(text: TimeFormat.hhmm(now, timeZone: zone, use24h: engine.settings.use24h),
                           theme: theme,
                           isDimmed: isDimmed,
                           digitWidth: 30,
                           digitHeight: 46)

                HStack(spacing: 6) {
                    LCDLabel(TimeFormat.weekday(now, timeZone: zone), color: ink, size: 10, opacity: 0.8)
                    LCDLabel(TimeFormat.dayMonth(now, timeZone: zone), color: ink, size: 10, opacity: 0.8)
                    LCDLabel(TimeFormat.offsetCode(zone), color: theme.accent, size: 10, opacity: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { cycleCity() }

            Divider().overlay(ink.opacity(0.2))

            HStack(spacing: 8) {
                DataCell(label: "HOME " + TimeFormat.cityCode(.current),
                         value: TimeFormat.hhmm(now, use24h: engine.settings.use24h),
                         unit: nil, theme: theme, isDimmed: isDimmed)
                DataCell(label: "SEC",
                         value: TimeFormat.seconds(now),
                         unit: nil, theme: theme, isDimmed: isDimmed)
            }
            .padding(.horizontal, 8)

            if !isDimmed {
                LCDLabel("ТАП — СЛЕДУЮЩИЙ ГОРОД", color: ink, size: 8, opacity: 0.45)
            }
        }
    }

    private func cycleCity() {
        let cities = Self.cities
        let index = cities.firstIndex(of: engine.settings.dualTimeZoneID) ?? 0
        engine.settings.dualTimeZoneID = cities[(index + 1) % cities.count]
        Haptics.button()
    }
}
