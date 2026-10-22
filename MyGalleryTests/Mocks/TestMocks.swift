//
//  TestMocks.swift
//  MyGalleryTests
//

import Foundation
@testable import MyGallery

enum TestError: Error, Equatable {
    case network
}

func makeImage(_ id: String, author: String = "Author", width: Int = 4000, height: Int = 3000) -> GalleryImage {
    GalleryImage(
        id: id,
        author: author,
        width: width,
        height: height,
        url: URL(string: "https://unsplash.com/photos/\(id)"),
        downloadURL: URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
    )
}

func makePage(start: Int, count: Int) -> [GalleryImage] {
    (start..<(start + count)).map { makeImage("\($0)", author: "Author \($0)") }
}

/// Repository returning queued results per call.
final class MockImageRepository: ImageRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var results: [Result<[GalleryImage], Error>]
    private(set) var requestedPages: [Int] = []

    init(results: [Result<[GalleryImage], Error>]) {
        self.results = results
    }

    func fetchImages(page: Int, limit: Int) async throws -> [GalleryImage] {
        let result: Result<[GalleryImage], Error> = lock.withLock {
            requestedPages.append(page)
            return results.isEmpty ? .success([]) : results.removeFirst()
        }
        return try result.get()
    }
}

/// HTTP client returning a fixed response and counting calls.
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    var result: Result<Data, Error>
    private(set) var callCount = 0

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func data(from url: URL) async throws -> Data {
        let current: Result<Data, Error> = lock.withLock {
            callCount += 1
            return result
        }
        return try current.get()
    }
}

@MainActor
final class MockAuthService: AuthenticationServiceProtocol {
    var signInResult: Result<AuthUser, Error>
    var restoredUser: AuthUser?
    var signOutError: Error?
    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0

    init(signInResult: Result<AuthUser, Error>, restoredUser: AuthUser? = nil) {
        self.signInResult = signInResult
        self.restoredUser = restoredUser
    }

    func signIn() async throws -> AuthUser {
        signInCallCount += 1
        return try signInResult.get()
    }

    func restorePreviousSignIn() async -> AuthUser? { restoredUser }

    func signOut() async throws {
        signOutCallCount += 1
        if let signOutError { throw signOutError }
    }

    func handle(url: URL) -> Bool { false }
}

let sampleUser = AuthUser(
    id: "123",
    name: "Rahul",
    email: "rahul@example.com",
    profileImageURL: nil
)

func makeTemporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("MyGalleryTests-\(UUID().uuidString)", isDirectory: true)
}
