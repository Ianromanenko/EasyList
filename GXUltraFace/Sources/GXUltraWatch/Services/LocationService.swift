import CoreLocation
import Observation

/// Компас и координаты. Ultra умеет точный магнитный курс — на этом
/// построены модули CMP (азимут + возврат по следу) и SUN (восход/закат).
@MainActor
@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()

    var heading: Double?              // магнитный курс, градусы
    var trueHeading: Double?
    var headingAccuracy: Double?
    var coordinate: CLLocationCoordinate2D?
    var altitudeGPS: Double?
    var speed: Double?
    var authorization: CLAuthorizationStatus = .notDetermined

    /// Заданное направление (bearing lock) — стрелка, к которой возвращаешься.
    var markedBearing: Double?
    /// Точка старта для «вернуться по следу».
    var markedLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
    }

    func start() {
        authorization = manager.authorizationStatus
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func markCurrentBearing() {
        markedBearing = heading
        markedLocation = coordinate
    }

    func clearMark() {
        markedBearing = nil
        markedLocation = nil
    }

    /// Разница между текущим курсом и отмеченным — стрелка «домой».
    var relativeBearing: Double? {
        guard let heading, let markedBearing else { return nil }
        var delta = markedBearing - heading
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }

    var distanceToMark: Double? {
        guard let coordinate, let markedLocation else { return nil }
        let here = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let there = CLLocation(latitude: markedLocation.latitude, longitude: markedLocation.longitude)
        return here.distance(from: there)
    }

    /// Румб из курса: N / NE / E / ...
    static func cardinal(for degrees: Double) -> String {
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(((degrees.truncatingRemainder(dividingBy: 360) + 360) / 22.5).rounded()) % 16
        return points[index]
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magnetic = newHeading.magneticHeading
        let trueH = newHeading.trueHeading
        let accuracy = newHeading.headingAccuracy
        Task { @MainActor [weak self] in
            self?.heading = magnetic
            self?.trueHeading = trueH >= 0 ? trueH : nil
            self?.headingAccuracy = accuracy
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        let altitude = location.altitude
        let speed = location.speed
        Task { @MainActor [weak self] in
            self?.coordinate = coordinate
            self?.altitudeGPS = altitude
            self?.speed = speed >= 0 ? speed : nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in self?.authorization = status }
    }
}
