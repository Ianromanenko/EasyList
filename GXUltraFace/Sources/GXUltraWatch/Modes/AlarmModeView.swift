import SwiftUI

/// Будильники: список, до ближайшего — обратный отсчёт.
/// Время правится колёсиком, включение — тапом по строке.
struct AlarmModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool
    @State private var selection: AlarmStore.Alarm.ID?

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let store = engine.alarms

        VStack(spacing: 5) {
            if let next = store.nextAlarm {
                VStack(spacing: 1) {
                    BigReadout(text: next.alarm.time,
                               theme: theme,
                               isDimmed: isDimmed,
                               digitWidth: 28,
                               digitHeight: 42)
                    LCDLabel("ЧЕРЕЗ \(TimeFormat.duration(next.date.timeIntervalSinceNow))",
                             color: theme.accent, size: 10, opacity: 1)
                }
            } else {
                VStack(spacing: 2) {
                    SegmentText(text: "NO ALM",
                                style: .fourteen,
                                color: ink,
                                ghostOpacity: theme.ghostOpacity,
                                digitWidth: 16,
                                digitHeight: 24,
                                spacing: 2,
                                weight: 0.2,
                                showsGhosts: false)
                    LCDLabel("КНОПКА +ALM", color: ink, size: 9, opacity: 0.5)
                }
            }

            ScrollView {
                VStack(spacing: 3) {
                    ForEach(store.alarms) { alarm in
                        alarmRow(alarm, theme: theme, ink: ink)
                    }
                }
                .padding(.horizontal, 8)
            }

            HStack {
                LCDLabel("SIG", color: engine.settings.hourlyChime ? theme.accent : ink,
                         size: 10, opacity: 1)
                LCDLabel("часовой сигнал", color: ink, size: 9, opacity: 0.5)
                Spacer()
            }
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                engine.settings.hourlyChime.toggle()
                store.setHourlyChime(engine.settings.hourlyChime)
                Haptics.button()
            }
        }
    }

    private func alarmRow(_ alarm: AlarmStore.Alarm, theme: FaceTheme, ink: Color) -> some View {
        let isSelected = selection == alarm.id
        return HStack(spacing: 6) {
            IndicatorLamp(title: "ON", isOn: alarm.isEnabled, color: theme.accent, size: 9)
            SegmentText(text: alarm.time,
                        style: .seven,
                        color: alarm.isEnabled ? ink : ink.opacity(0.4),
                        ghostOpacity: theme.ghostOpacity,
                        digitWidth: 11,
                        digitHeight: 17,
                        spacing: 1.5,
                        weight: 0.2,
                        showsGhosts: false)
            Spacer()
            if isSelected {
                // Правка времени: шаг 5 минут, как перебор разрядов на Casio.
                HStack(spacing: 4) {
                    stepButton("-5", theme: theme, ink: ink) { engine.alarms.adjust(alarm, byMinutes: -5) }
                    stepButton("+5", theme: theme, ink: ink) { engine.alarms.adjust(alarm, byMinutes: 5) }
                }
            } else {
                Button {
                    engine.alarms.remove(alarm)
                    Haptics.button()
                } label: {
                    LCDLabel("DEL", color: ink, size: 9, opacity: 0.5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? theme.accent : ink.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            engine.alarms.toggle(alarm)
        }
        .onLongPressGesture {
            selection = isSelected ? nil : alarm.id
            Haptics.modeChange()
        }
    }

    private func stepButton(_ title: String,
                            theme: FaceTheme,
                            ink: Color,
                            action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.button()
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(theme.glass)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(theme.accent))
        }
        .buttonStyle(.plain)
    }
}
