import Foundation
import CoreLocation

/// Астрономия без интернета: восход, закат, солнечный полдень, золотой час
/// и фаза Луны считаются локально (упрощённые формулы NOAA, точность ~1–2 мин).
enum SolarCalculator {

    struct DayInfo {
        var sunrise: Date?
        var sunset: Date?
        var solarNoon: Date
        var civilDawn: Date?
        var civilDusk: Date?
        var goldenHourEnd: Date?      // конец утреннего золотого часа
        var goldenHourStart: Date?    // начало вечернего
        var dayLength: TimeInterval?

        /// Доля светового дня, которая уже прошла (0...1) — для солнечной шкалы.
        func progress(at date: Date = .now) -> Double? {
            guard let sunrise, let sunset, sunset > sunrise else { return nil }
            let ratio = date.timeIntervalSince(sunrise) / sunset.timeIntervalSince(sunrise)
            return min(max(ratio, 0), 1)
        }

        func isDaylight(at date: Date = .now) -> Bool {
            guard let sunrise, let sunset else { return true }
            return date >= sunrise && date <= sunset
        }
    }

    static func dayInfo(for date: Date, coordinate: CLLocationCoordinate2D) -> DayInfo {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        let jd = julianDay(from: date)
        let n = (jd - 2451545.0 + 0.0008).rounded()
        let jStar = n - lon / 360.0
        let M = (357.5291 + 0.98560028 * jStar).truncatingRemainder(dividingBy: 360)
        let Mrad = M * .pi / 180
        let C = 1.9148 * sin(Mrad) + 0.0200 * sin(2 * Mrad) + 0.0003 * sin(3 * Mrad)
        let lambda = (M + C + 180 + 102.9372).truncatingRemainder(dividingBy: 360)
        let lambdaRad = lambda * .pi / 180
        let jTransit = 2451545.0 + jStar + 0.0053 * sin(Mrad) - 0.0069 * sin(2 * lambdaRad)

        let declination = asin(sin(lambdaRad) * sin(23.44 * .pi / 180))
        let latRad = lat * .pi / 180

        func event(angle: Double) -> (rise: Date, set: Date)? {
            let cosOmega = (sin(angle * .pi / 180) - sin(latRad) * sin(declination))
                / (cos(latRad) * cos(declination))
            guard cosOmega >= -1, cosOmega <= 1 else { return nil }   // полярный день/ночь
            let omega = acos(cosOmega) * 180 / .pi
            let rise = jTransit - omega / 360
            let set = jTransit + omega / 360
            return (SolarCalculator.date(fromJulian: rise), SolarCalculator.date(fromJulian: set))
        }

        let official = event(angle: -0.833)
        let civil = event(angle: -6)
        let golden = event(angle: 6)

        return DayInfo(
            sunrise: official?.rise,
            sunset: official?.set,
            solarNoon: SolarCalculator.date(fromJulian: jTransit),
            civilDawn: civil?.rise,
            civilDusk: civil?.set,
            goldenHourEnd: golden?.rise,
            goldenHourStart: golden?.set,
            dayLength: official.map { $0.set.timeIntervalSince($0.rise) }
        )
    }

    // MARK: - Луна

    struct MoonInfo {
        var phase: Double          // 0 = новолуние, 0.5 = полнолуние
        var illumination: Double   // 0...1
        var ageDays: Double

        var name: String {
            switch phase {
            case ..<0.03, 0.97...: return "NEW"
            case ..<0.22: return "WAX CR"
            case ..<0.28: return "1ST QT"
            case ..<0.47: return "WAX GB"
            case ..<0.53: return "FULL"
            case ..<0.72: return "WAN GB"
            case ..<0.78: return "3RD QT"
            default: return "WAN CR"
            }
        }
    }

    private static let synodicMonth = 29.530588853
    /// Опорное новолуние: 6 января 2000, 18:14 UTC.
    private static let knownNewMoon = Date(timeIntervalSince1970: 947_182_440)

    static func moonInfo(for date: Date = .now) -> MoonInfo {
        let days = date.timeIntervalSince(knownNewMoon) / 86400
        var phase = (days / synodicMonth).truncatingRemainder(dividingBy: 1)
        if phase < 0 { phase += 1 }
        let illumination = (1 - cos(2 * .pi * phase)) / 2
        return MoonInfo(phase: phase, illumination: illumination, ageDays: phase * synodicMonth)
    }

    // MARK: - Юлианские даты

    static func julianDay(from date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    static func date(fromJulian jd: Double) -> Date {
        Date(timeIntervalSince1970: (jd - 2440587.5) * 86400.0)
    }
}
