import SwiftUI
import Observation
import WatchKit
import WidgetKit

/// Мозг циферблата: держит сервисы, текущий режим, состояние подсветки
/// и раздаёт действия кнопкам. Вьюхи остаются тонкими.
@MainActor
@Observable
final class FaceEngine {
    /// Один движок на приложение: к нему обращаются и вью, и App Intents
    /// (боковая кнопка «Действие», Shortcuts, двойной тап).
    static let shared = FaceEngine()

    let settings = FaceSettings.shared
    let health = HealthService()
    let motion = MotionService()
    let location = LocationService()
    let weather = WeatherService()
    let water = WaterService()
    let battery = BatteryService()
    let stopwatch = StopwatchEngine()
    let timer = TimerEngine()
    let alarms = AlarmStore()
    let workout = WorkoutController()

    var mode: FaceMode = .time
    var backlightUntil: Date?
    var showsSettings = false
    var lastChimedHour: Int?

    /// Режимы, доступные на этом устройстве: DIVE прячем, если нет датчика.
    var availableModes: [FaceMode] {
        FaceMode.allCases.filter { mode in
            switch mode {
            case .dive: return water.isSupported
            case .compass: return location.authorization != .denied
            default: return true
            }
        }
    }

    var theme: FaceTheme { settings.theme }

    var isBacklit: Bool {
        guard let backlightUntil else { return false }
        return backlightUntil > .now
    }

    // MARK: - Жизненный цикл

    func bootstrap() async {
        battery.start()
        motion.start()
        location.start()
        water.start()
        await health.requestAuthorization()
        health.start()
        await alarms.requestAuthorization()
        alarms.setHourlyChime(settings.hourlyChime)
        await weather.refresh(for: location.coordinate)
        publishSnapshot()
        scheduleBackgroundRefresh()
    }

    /// Следующее пробуждение в фоне — через 15 минут.
    func scheduleBackgroundRefresh() {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(15 * 60),
            userInfo: nil
        ) { _ in }
    }

    func refreshPeriodic() {
        battery.refresh()
        health.refreshSummaries()
        health.refreshDailyTotals()
        Task { [weak self] in
            guard let self else { return }
            await self.weather.refresh(for: self.location.coordinate)
            self.publishSnapshot()
        }
        publishSnapshot()
    }

    /// Отдаём текущие значения осложнениям на штатных циферблатах.
    func publishSnapshot() {
        var snapshot = FaceSnapshot()
        snapshot.themeID = settings.theme.rawValue
        snapshot.heartRate = health.heartRate.map { Int($0) }
        snapshot.steps = max(health.steps, motion.currentSteps)
        snapshot.batteryPercent = battery.percent
        snapshot.altitude = (motion.absoluteAltitude ?? location.altitudeGPS).map { Int($0) }
        snapshot.temperature = weather.temperature.map { Int($0.rounded()) }
        snapshot.movePercent = Int(health.moveRatio * 100)
        snapshot.nextAlarm = alarms.nextAlarm?.alarm.time
        snapshot.stopwatchRunning = stopwatch.isRunning
        snapshot.updated = .now
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func teardown() {
        health.stop()
        motion.stop()
        location.stop()
        battery.stop()
    }

    // MARK: - Взаимодействие

    /// Тап по стеклу = кнопка LIGHT: подсветка + щелчок.
    func flashBacklight() {
        backlightUntil = Date.now.addingTimeInterval(settings.backlightSeconds)
        Haptics.button()
    }

    func select(_ newMode: FaceMode) {
        guard newMode != mode else { return }
        mode = newMode
        Haptics.modeChange()
    }

    func cycleMode(forward: Bool = true) {
        let modes = availableModes
        guard let index = modes.firstIndex(of: mode) else { return }
        let next = forward
            ? modes[(index + 1) % modes.count]
            : modes[(index - 1 + modes.count) % modes.count]
        select(next)
    }

    /// Главное действие режима — вешается на двойной тап (watchOS 11+)
    /// и на боковую кнопку «Действие» через App Intents.
    func primaryAction() {
        switch mode {
        case .stopwatch: stopwatch.toggle()
        case .timer: timer.toggle()
        case .workout: workout.isActive ? workout.togglePause() : workout.start(workout.activity)
        case .compass: location.markedBearing == nil ? location.markCurrentBearing() : location.clearMark()
        case .baro: motion.calibrateZero()
        case .dive: water.resetDive()
        case .alarm: if let next = alarms.nextAlarm { alarms.toggle(next.alarm) }
        default: flashBacklight()
        }
    }

    /// Часовой сигнал, когда экран активен: Casio-щелчок ровно в :00.
    func checkHourlyChime(at date: Date) {
        guard settings.hourlyChime else { return }
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        guard components.minute == 0, (components.second ?? 0) < 2 else { return }
        guard lastChimedHour != components.hour else { return }
        lastChimedHour = components.hour
        Haptics.hourlyChime()
    }

    // MARK: - Кнопки корпуса

    func softKeys() -> [SoftKey] {
        let light = SoftKey(label: "LIGHT") { [weak self] in self?.flashBacklight() }
        let modeKey = SoftKey(label: "MODE") { [weak self] in self?.cycleMode() }
        let adjust = SoftKey(label: "ADJ") { [weak self] in
            self?.showsSettings = true
            Haptics.button()
        }

        switch mode {
        case .stopwatch:
            return [modeKey,
                    SoftKey(label: stopwatch.isRunning ? "STOP" : "START", isAccented: true) { [weak self] in
                        self?.stopwatch.toggle()
                    },
                    SoftKey(label: stopwatch.isRunning ? "LAP" : "RESET") { [weak self] in
                        self?.stopwatch.lap()
                    },
                    light]
        case .timer:
            return [modeKey,
                    SoftKey(label: timer.isRunning ? "STOP" : "START", isAccented: true) { [weak self] in
                        self?.timer.toggle()
                    },
                    SoftKey(label: "RESET") { [weak self] in self?.timer.reset() },
                    light]
        case .compass:
            return [modeKey,
                    SoftKey(label: location.markedBearing == nil ? "MARK" : "CLR", isAccented: true) { [weak self] in
                        guard let self else { return }
                        self.location.markedBearing == nil ? self.location.markCurrentBearing() : self.location.clearMark()
                        Haptics.button()
                    },
                    adjust,
                    light]
        case .baro:
            return [modeKey,
                    SoftKey(label: "ZERO", isAccented: true) { [weak self] in
                        self?.motion.calibrateZero()
                        Haptics.button()
                    },
                    adjust,
                    light]
        case .workout:
            return [modeKey,
                    SoftKey(label: workout.isActive ? (workout.isPaused ? "GO" : "PAUSE") : "START", isAccented: true) { [weak self] in
                        guard let self else { return }
                        self.workout.isActive ? self.workout.togglePause() : self.workout.start(self.workout.activity)
                    },
                    SoftKey(label: "END") { [weak self] in self?.workout.end() },
                    light]
        case .alarm:
            return [modeKey,
                    SoftKey(label: "+ALM", isAccented: true) { [weak self] in
                        let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
                        self?.alarms.add(hour: now.hour ?? 7, minute: 0)
                        Haptics.button()
                    },
                    adjust,
                    light]
        case .dive:
            return [modeKey,
                    SoftKey(label: "RESET", isAccented: true) { [weak self] in
                        self?.water.resetDive()
                        Haptics.button()
                    },
                    adjust,
                    light]
        default:
            return [modeKey,
                    SoftKey(label: "DATA", isAccented: true) { [weak self] in
                        guard let self else { return }
                        let all = FaceSettings.Readout.allCases
                        let index = all.firstIndex(of: self.settings.pinnedReadout) ?? 0
                        self.settings.pinnedReadout = all[(index + 1) % all.count]
                        Haptics.button()
                    },
                    adjust,
                    light]
        }
    }
}
