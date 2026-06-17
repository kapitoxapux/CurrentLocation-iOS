import Foundation
import CoreLocation

struct LocationPoint: Codable {
    let id: String
    let lat: Double
    let lon: Double
    let accuracy: Float
    let timestamp: Int64   // Unix milliseconds, как в Android
    let provider: String

    init(location: CLLocation) {
        self.id = UUID().uuidString
        self.lat = location.coordinate.latitude
        self.lon = location.coordinate.longitude
        self.accuracy = Float(location.horizontalAccuracy)
        self.timestamp = Int64(location.timestamp.timeIntervalSince1970 * 1000)
        // iOS не различает GPS/Network как Android — используем accuracy как признак
        self.provider = location.horizontalAccuracy < 50 ? "gps" : "network"
    }
}
