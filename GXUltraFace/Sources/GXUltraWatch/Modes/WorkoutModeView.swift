import SwiftUI
import HealthKit

/// Тренировка с циферблата: выбор активности, старт, живые метрики.
/// Пишется в Здоровье обычной тренировкой — данные не теряются.
struct WorkoutModeView: View {
    var engine: FaceEngine
    var now: Date
    var isDimmed: Bool

    var body: some View {
        let theme = engine.theme
        let ink = theme.ink(dimmed: isDimmed)
        let workout = engine.workout

        VStack(spacing: 5) {
            if workout.isActive {
                VStack(spacing: 1) {
                    SegmentText(text: WorkoutController.code(for: workout.activity),
                                style: .fourteen,
                                color: theme.accent,
                                ghostOpacity: theme.ghostOpacity,
                                digitWidth: 12,
                                digitHeight: 18,
                                spacing: 1.5,
                                weight: 0.2,
                                showsGhosts: false)
                    BigReadout(text: StopwatchEngine.format(workout.elapsed(at: now), showsHundredths: false),
                               theme: theme,
                               isDimmed: isDimmed,
                               digitWidth: 28,
                               digitHeight: 42)
                    LCDLabel(workout.isPaused ? "PAUSED" : "RECORDING",
                             color: workout.isPaused ? ink : theme.accent, size: 10, opacity: 1)
                }

                HStack(spacing: 8) {
                    DataCell(label: "HR",
                             value: (workout.heartRate ?? engine.health.heartRate).map { String(Int($0)) } ?? "---",
                             unit: "BPM", theme: theme, isDimmed: isDimmed, accented: true)
                    DataCell(label: "KCAL",
                             value: String(Int(workout.activeEnergy)),
                             unit: nil, theme: theme, isDimmed: isDimmed)
                    DataCell(label: "DIST",
                             value: String(format: "%.2f", workout.distance / 1000),
                             unit: "KM", theme: theme, isDimmed: isDimmed)
                }
                .padding(.horizontal, 8)
            } else {
                LCDLabel("ВЫБЕРИ АКТИВНОСТЬ", color: ink, size: 10, opacity: 0.6)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                    ForEach(WorkoutController.quickActivities, id: \.rawValue) { activity in
                        Button {
                            engine.workout.activity = activity
                            engine.workout.start(activity)
                        } label: {
                            Text(WorkoutController.code(for: activity))
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundStyle(theme.glass)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 5).fill(theme.accent.opacity(0.85)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}
