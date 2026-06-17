import Foundation

struct RegisterResponse: Decodable {
    let access_token: String
    let refresh_token: String
}

struct RefreshResponse: Decodable {
    let access_token: String
    let refresh_token: String
}

struct AuthClient {
    private let session = URLSession.shared

    func register(deviceID: String) async throws -> RegisterResponse {
        try await post(path: "/auth/register", body: ["android_id": deviceID])
    }

    func refresh(token: String) async throws -> RefreshResponse? {
        let url = url(path: "/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": token])

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try JSONDecoder().decode(RefreshResponse.self, from: data)
    }

    private func post<T: Decodable>(path: String, body: [String: String]) async throws -> T {
        var request = URLRequest(url: url(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func url(path: String) -> URL {
        URL(string: Config.apiBaseURL + path)!
    }
}
