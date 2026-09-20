import SwiftUI

/// Обратный отсчёт: крупные цифры, шкала остатка и пресеты в один тап.
struct TimerModeView: View {
    var engine: FaceEngine
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let timer = engine.timer

        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = timer.remaining(at: context.date)
            VStack(spacing: 6) {
                BigReadout(text: StopwatchEngine.format(remaining, showsHundredths: false),
                           theme: theme,
                           isDimmed: isDimmed,
                           digitWidth: 32,
                           digitHeight: 50)

                SegmentBar(value: timer.progress(at: context.date),
                           cells: 20,
                           color: remaining < 10 ? theme.accent : ink,
                           ghostOpacity: theme.ghostOpacity,
                           cellHeight: 6,
                           spacing: 1.5)
                .padding(.horizontal, 10)

                HStack(spacing: 4) {
                    LCDLabel(timer.isRunning ? "RUN" : "SET",
                             color: timer.isRunning ? theme.accent : ink, size: 10, opacity: 1)
                    Spacer()
                    LCDLabel("REPEAT", color: ink, size: 9, opacity: timer.repeats ? 1 : 0.3)
                        .onTapGesture {
                            timer.repeats.toggle()
                            Haptics.button()
                        }
                }
                .padding(.horizontal, 10)

                if !isDimmed {
                    HStack(spacing: 3) {
                        ForEach(TimerEngine.presets, id: \.self) { preset in
                            Button {
                                timer.setDuration(preset)
                                Haptics.button()
                            } label: {
                                Text(preset >= 3600 ? "1H" : "\(Int(preset / 60))M")
                                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(abs(timer.duration - preset) < 1 ? theme.glass : ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(abs(timer.duration - preset) < 1 ? theme.accent : ink.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .onChange(of: Int(remaining)) { _, value in
                if value == 0 { timer.handleFired() }
            }
        }
    }
}
