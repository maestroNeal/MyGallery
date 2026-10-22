//
//  APIClient.swift
//  MyGallery
//

import Foundation

nonisolated enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let code):
            return "The server returned an error (\(code))."
        case .decoding:
            return "The server returned data in an unexpected format."
        }
    }
}

/// Minimal HTTP abstraction so networking can be mocked in tests.
nonisolated protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> Data
}

nonisolated struct URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }
        return data
    }
}

nonisolated struct APIClient: Sendable {
    let httpClient: HTTPClient

    init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func get<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let data = try await httpClient.data(from: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
