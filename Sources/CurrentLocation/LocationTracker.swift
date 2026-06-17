import CoreLocation
import Foundation

// Аналог LocationTrackingService.kt — управляет CLLocationManager и периодической отправкой
@MainActor
final class LocationTracker: NSObject, ObservableObject {
    @Published var isTracking = false
    @Published var lastLocation: CLLocation?
    @Published var statusMessage = "Ожидание..."

    private let manager = CLLocationManager()
    private let buffer  = LocationBuffer()
    private let sender  = LocationSender()
    private var flushTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter   = Config.locationDistanceFilter
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        guard !isTracking else { return }
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        isTracking = true
        statusMessage = "Трекинг активен"
        startFlushLoop()
        UserDefaults.standard.set(true, forKey: "tracking_enabled")
    }

    func stop() {
        manager.stopUpdatingLocation()
        flushTask?.cancel()
        flushTask = nil
        isTracking = false
        statusMessage = "Остановлен"
        UserDefaults.standard.set(false, forKey: "tracking_enabled")
    }

    func restoreIfNeeded() {
        if UserDefaults.standard.bool(forKey: "tracking_enabled") { start() }
    }

    // MARK: - Private

    private func startFlushLoop() {
        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Config.sendInterval * 1_000_000_000))
                await self?.flush()
            }
        }
    }

    private func flush() async {
        let points = await buffer.getAll()
        guard !points.isEmpty else { return }
        let success = await sender.send(points: points)
        if success { await buffer.clearUpTo(points.count) }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationTracker: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        let point = LocationPoint(location: location)
        Task { await buffer.add(point) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "Ошибка: \(error.localizedDescription)"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            statusMessage = isTracking ? "Трекинг активен" : "Готов к запуску"
        case .authorizedWhenInUse:
            statusMessage = "Нет разрешения 'Всегда' — фон не работает"
        case .denied, .restricted:
            statusMessage = "Доступ к геолокации запрещён"
            stop()
        default:
            break
        }
    }
}
