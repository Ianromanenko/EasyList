import CoreMotion
import Observation

/// Модуль FROGMAN: датчик погружения Ultra отдаёт глубину, температуру воды
/// и состояние погружения. На не-Ultra устройствах просто не стартует.
@MainActor
@Observable
final class WaterService: NSObject {
    var depth: Double?              // м
    var waterTemperature: Double?   // °C
    var pressureKPa: Double?
    var submerged = false
    var isSupported = false
    var maxDepthThisDive: Double = 0

    #if os(watchOS)
    private var manager: CMWaterSubmersionManager?
    #endif

    func start() {
        #if os(watchOS)
        guard CMWaterSubmersionManager.waterSubmersionAvailable else {
            isSupported = false
            return
        }
        isSupported = true
        let manager = CMWaterSubmersionManager()
        manager.delegate = self
        self.manager = manager
        #endif
    }

    func resetDive() { maxDepthThisDive = 0 }
}

#if os(watchOS)
extension WaterService: CMWaterSubmersionManagerDelegate {
    nonisolated func manager(_ manager: CMWaterSubmersionManager,
                             didUpdate measurement: CMWaterSubmersionMeasurement) {
        let depth = measurement.depth?.converted(to: .meters).value
        let pressure = measurement.pressure?.converted(to: .kilopascals).value
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.depth = depth
            self.pressureKPa = pressure
            if let depth { self.maxDepthThisDive = max(self.maxDepthThisDive, depth) }
        }
    }

    nonisolated func manager(_ manager: CMWaterSubmersionManager,
                             didUpdate temperature: CMWaterTemperature) {
        let celsius = temperature.temperature.converted(to: .celsius).value
        Task { @MainActor [weak self] in self?.waterTemperature = celsius }
    }

    nonisolated func manager(_ manager: CMWaterSubmersionManager,
                             didUpdate event: CMWaterSubmersionEvent) {
        let isSubmerged = event.state == .submergedShallow || event.state == .submergedDeep
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.submerged = isSubmerged
            if !isSubmerged { self.depth = nil }
        }
    }

    nonisolated func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: any Error) {
        Task { @MainActor [weak self] in self?.isSupported = false }
    }
}
#endif
