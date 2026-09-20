import SwiftUI
import WatchKit

/// Корневой экран: статусная строка сверху, «окно» режима в центре,
/// ряд кнопок снизу. Всё остальное меняется внутри окна.
struct FaceView: View {
    @State private var engine = FaceEngine.shared
    @State private var crown: Double = 0
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // В always-on кадре обновляемся раз в минуту — иначе сажаем батарею.
        TimelineView(.periodic(from: .now, by: isLuminanceReduced ? 60 : 1)) { context in
            content(now: context.date)
                .onChange(of: context.date) { _, date in
                    engine.checkHourlyChime(at: date)
                }
        }
        .task { await engine.bootstrap() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { engine.refreshPeriodic() }
        }
        .sheet(isPresented: Binding(get: { engine.showsSettings },
                                    set: { engine.showsSettings = $0 })) {
            SettingsView(engine: engine)
        }
    }

    private func content(now: Date) -> some View {
        let theme = engine.theme
        let dimmed = isLuminanceReduced

        return ZStack {
            LCDBackground(theme: theme, isBacklit: engine.isBacklit, isDimmed: dimmed)

            VStack(spacing: 4) {
                StatusStrip(engine: engine, isDimmed: dimmed)

                ModeWindow(engine: engine, now: now, isDimmed: dimmed)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { engine.flashBacklight() }

                if !dimmed {
                    SoftKeyBar(keys: engine.softKeys(), theme: theme, isDimmed: dimmed)
                }
            }
            .padding(.vertical, 2)

            // Невидимая кнопка ловит двойной тап (watchOS 11+) и жест «Действие».
            Button(action: { engine.primaryAction() }) { EmptyView() }
                .handGestureShortcut(.primaryAction)
                .opacity(0)
                .accessibilityLabel(Text("Основное действие режима"))
        }
        .focusable()
        .digitalCrownRotation($crown,
                              from: 0,
                              through: Double(max(engine.availableModes.count - 1, 1)),
                              by: 1,
                              sensitivity: .low,
                              isContinuous: true,
                              isHapticFeedbackEnabled: true)
        .onChange(of: crown) { _, value in
            guard engine.settings.crownSwitchesMode else { return }
            let modes = engine.availableModes
            let index = Int(value.rounded()) % max(modes.count, 1)
            engine.select(modes[max(index, 0)])
        }
    }
}

/// Окно режима — то, что на Casio меняется по кнопке MODE.
struct ModeWindow: View {
    var engine: FaceEngine
    var now: Date
    var isDimmed: Bool

    var body: some View {
        Group {
            switch engine.mode {
            case .time:      TimeModeView(engine: engine, now: now, isDimmed: isDimmed)
            case .vitals:    VitalsModeView(engine: engine, isDimmed: isDimmed)
            case .stopwatch: StopwatchModeView(engine: engine, isDimmed: isDimmed)
            case .timer:     TimerModeView(engine: engine, isDimmed: isDimmed)
            case .alarm:     AlarmModeView(engine: engine, isDimmed: isDimmed)
            case .dual:      DualTimeModeView(engine: engine, now: now, isDimmed: isDimmed)
            case .sun:       SunModeView(engine: engine, now: now, isDimmed: isDimmed)
            case .compass:   CompassModeView(engine: engine, isDimmed: isDimmed)
            case .baro:      BaroModeView(engine: engine, isDimmed: isDimmed)
            case .dive:      DiveModeView(engine: engine, isDimmed: isDimmed)
            case .workout:   WorkoutModeView(engine: engine, now: now, isDimmed: isDimmed)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.15), value: engine.mode)
    }
}

// MARK: - Общие кусочки, которые нужны всем режимам

/// Большая строка времени/значения — главный элемент любого режима.
struct BigReadout: View {
    var text: String
    var theme: FaceTheme
    var isDimmed: Bool
    var digitWidth: CGFloat = 34
    var digitHeight: CGFloat = 54
    var style: SegStyle = .seven

    var body: some View {
        SegmentText(text: text,
                    style: style,
                    color: theme.ink(dimmed: isDimmed),
                    ghostOpacity: theme.ghostOpacity,
                    digitWidth: digitWidth,
                    digitHeight: digitHeight,
                    spacing: 2.5,
                    weight: 0.175)
        .frame(maxWidth: .infinity)
    }
}

/// Маленькое окно данных: подпись + значение. Из таких собраны все режимы.
struct DataCell: View {
    var label: String
    var value: String
    var unit: String?
    var theme: FaceTheme
    var isDimmed: Bool
    var accented: Bool = false
    var action: (() -> Void)?

    var body: some View {
        let tint = accented ? theme.accent : theme.ink(dimmed: isDimmed)
        VStack(alignment: .leading, spacing: 1) {
            LCDLabel(label, color: theme.ink(dimmed: isDimmed), size: 9, opacity: 0.55)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                SegmentText(text: value,
                            style: value.contains(where: { $0.isLetter }) ? .fourteen : .seven,
                            color: tint,
                            ghostOpacity: theme.ghostOpacity,
                            digitWidth: 11,
                            digitHeight: 17,
                            spacing: 1.5,
                            weight: 0.2,
                            showsGhosts: false)
                if let unit {
                    LCDLabel(unit, color: tint, size: 9, opacity: 0.7)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { action?() }
    }
}
