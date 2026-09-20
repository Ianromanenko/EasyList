import CoreMotion
import Observation

/// Барометр + альтиметр + шагомер. Это то, что делает «Pro Trek»-модули
/// осмысленными: высота, тренд давления (погода на ближайшие часы), темп.
@MainActor
@Observable
final class MotionService {
    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()

    var relativeAltitude: Double = 0        // м от точки старта
    var absoluteAltitude: Double?           // м над уровнем моря (watchOS 15+ / Ultra)
    var pressureKPa: Double?
    var pressureHistory: [Double] = []      // для гистограммы тренда
    var altitudeHistory: [Double] = []
    var cadence: Double?                    // шагов/с
    var pace: Double?                       // с/м
    var currentSteps: Int = 0
    var isAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    private var baselineAltitude: Double?

    func start() {
        startAltimeter()
        startPedometer()
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        if #available(watchOS 15.0, *) { altimeter.stopAbsoluteAltitudeUpdates() }
        pedometer.stopUpdates()
    }

    /// Кнопка «обнулить высоту» — как выставить нулевую отметку на Pro Trek.
    func calibrateZero() {
        baselineAltitude = absoluteAltitude ?? relativeAltitude
        relativeAltitude = 0
    }

    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let kPa = data.pressure.doubleValue
            self.pressureKPa = kPa
            self.relativeAltitude = data.relativeAltitude.doubleValue
            self.pressureHistory.append(kPa)
            if self.pressureHistory.count > 360 { self.pressureHistory.removeFirst() }
            self.altitudeHistory.append(self.absoluteAltitude ?? self.relativeAltitude)
            if self.altitudeHistory.count > 360 { self.altitudeHistory.removeFirst() }
        }

        if #available(watchOS 15.0, *), CMAltimeter.isAbsoluteAltitudeAvailable() {
            altimeter.startAbsoluteAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.absoluteAltitude = data.altitude
                if let baseline = self.baselineAltitude {
                    self.relativeAltitude = data.altitude - baseline
                }
            }
        }
    }

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Calendar.current.startOfDay(for: Date())) { [weak self] data, _ in
            guard let self, let data else { return }
            self.currentSteps = data.numberOfSteps.intValue
            self.cadence = data.currentCadence?.doubleValue
            self.pace = data.currentPace?.doubleValue
        }
    }

    /// Давление в гПа — в этих единицах его читают метеосводки.
    var pressureHPa: Double? { pressureKPa.map { $0 * 10 } }

    /// Тренд за последние ~30 минут: падает — портится погода.
    var pressureTrend: PressureTrend {
        guard pressureHistory.count > 12 else { return .steady }
        let recent = pressureHistory.suffix(12).reduce(0, +) / 12
        let older = pressureHistory.prefix(12).reduce(0, +) / 12
        let deltaHPa = (recent - older) * 10
        if deltaHPa > 0.6 { return .rising }
        if deltaHPa < -0.6 { return .falling }
        return .steady
    }

    enum PressureTrend {
        case rising, steady, falling

        var code: String {
            switch self {
            case .rising: return "UP"
            case .steady: return "STDY"
            case .falling: return "DOWN"
            }
        }

        /// Грубый, но честный «народный барометр».
        var forecast: String {
            switch self {
            case .rising: return "CLEAR"
            case .steady: return "STABLE"
            case .falling: return "RAIN"
            }
        }
    }
}
