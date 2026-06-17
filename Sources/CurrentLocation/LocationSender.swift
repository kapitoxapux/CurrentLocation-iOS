import Foundation
import UIKit

// Отправка точек на сервер — аналог LocationSender.kt
actor LocationSender {
    private let authClient = AuthClient()
    private let session = URLSession.shared

    private enum SendResult { case success, unauthorized, rateLimited, error }

    private static let accessKey  = "access_token"
    private static let refreshKey = "refresh_token"
    private static let deviceKey  = "device_id"

    func send(points: [LocationPoint]) async -> Bool {
        guard let token = await ensureToken() else { return false }
        switch await doSend(points: points, token: token) {
        case .success:      return true
        case .unauthorized:
            guard let newToken = await rotateToken() else { return false }
            return await doSend(points: points, token: newToken) == .success
        case .rateLimited, .error: return false
        }
    }

    // MARK: - Private

    private func ensureToken() async -> String? {
        if let t = KeychainStorage.get(forKey: Self.accessKey) { return t }
        return await registerDevice()
    }

    private func registerDevice() async -> String? {
        let deviceID = deviceIdentifier()
        let deviceName = await MainActor.run { UIDevice.current.name }
        guard let r = try? await authClient.register(deviceID: deviceID, name: deviceName) else { return nil }
        KeychainStorage.save(r.access_token,  forKey: Self.accessKey)
        KeychainStorage.save(r.refresh_token, forKey: Self.refreshKey)
        return r.access_token
    }

    private func rotateToken() async -> String? {
        guard let refreshToken = KeychainStorage.get(forKey: Self.refreshKey) else {
            clearTokens(); return nil
        }
        guard let r = try? await authClient.refresh(token: refreshToken) else {
            clearTokens(); return nil
        }
        KeychainStorage.save(r.access_token,  forKey: Self.accessKey)
        KeychainStorage.save(r.refresh_token, forKey: Self.refreshKey)
        return r.access_token
    }

    private func clearTokens() {
        KeychainStorage.delete(forKey: Self.accessKey)
        KeychainStorage.delete(forKey: Self.refreshKey)
    }

    private func deviceIdentifier() -> String {
        if let saved = KeychainStorage.get(forKey: Self.deviceKey) { return saved }
        let id = UUID().uuidString
        KeychainStorage.save(id, forKey: Self.deviceKey)
        return id
    }

    private func doSend(points: [LocationPoint], token: String) async -> SendResult {
        guard let url = URL(string: Config.apiBaseURL + "/location/track"),
              let body = try? JSONEncoder().encode(["points": points]) else { return .error }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)",    forHTTPHeaderField: "Authorization")
        request.httpBody = body

        guard let (_, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse else { return .error }

        switch http.statusCode {
        case 200...299: return .success
        case 401:       return .unauthorized
        case 429:       return .rateLimited
        default:        return .error
        }
    }
}
