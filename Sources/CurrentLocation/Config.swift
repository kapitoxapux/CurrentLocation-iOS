import Foundation
import CoreLocation

enum Config {
    static let apiBaseURL = LocalConfig.apiBaseURL
    static let registrationKey = LocalConfig.registrationKey
    static let sendInterval: TimeInterval = 30
    static let locationDistanceFilter: CLLocationDistance = 5
}
