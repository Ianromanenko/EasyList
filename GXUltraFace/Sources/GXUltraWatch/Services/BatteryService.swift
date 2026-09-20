import WatchKit
import Observation

/// Индикатор батареи в стиле Casio: шкала из ячеек + процент.
@MainActor
@Observable
final class BatteryService {
    var level: Double = 1.0
    var isCharging = false
    var isLowPower = false

    private var timer: Timer?

    func start() {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        let device = WKInterfaceDevice.current()
        let raw = Double(device.batteryLevel)
        if raw >= 0 { level = raw }
        isCharging = device.batteryState == .charging || device.batteryState == .full
        isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    var percent: Int { Int((level * 100).rounded()) }
}
