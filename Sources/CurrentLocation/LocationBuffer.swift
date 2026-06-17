import Foundation

// Thread-safe буфер точек — аналог LocationBuffer.kt
actor LocationBuffer {
    private static let maxSize = 500
    private static let defaultsKey = "location_buffer"

    private var points: [LocationPoint] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([LocationPoint].self, from: data) {
            points = saved
        }
    }

    func add(_ point: LocationPoint) {
        if points.count >= Self.maxSize { points.removeFirst() }
        points.append(point)
        persist()
    }

    func getAll() -> [LocationPoint] { points }

    // Удаляет первые count точек — защита от race condition (аналог Android)
    func clearUpTo(_ count: Int) {
        points = Array(points.dropFirst(min(count, points.count)))
        persist()
    }

    var size: Int { points.count }

    private func persist() {
        guard let data = try? JSONEncoder().encode(points) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
