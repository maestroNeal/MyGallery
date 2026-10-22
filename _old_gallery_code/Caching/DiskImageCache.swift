//
//  DiskImageCache.swift
//  MyGallery
//

import CryptoKit
import Foundation

/// Two-level image cache: memory (NSCache) then files on disk.
/// Concurrent requests for the same URL share one download.
actor DiskImageCache: ImageCacheProtocol {
    static let shared = DiskImageCache()

    private let httpClient: HTTPClient
    private let directory: URL
    private let memory = NSCache<NSURL, NSData>()
    private var inFlight: [URL: Task<Data, Error>] = [:]

    init(httpClient: HTTPClient = URLSessionHTTPClient(), directory: URL? = nil) {
        self.httpClient = httpClient
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.directory = directory ?? base.appendingPathComponent("GalleryImages", isDirectory: true)
        memory.totalCostLimit = 100 * 1024 * 1024
    }

    func data(for url: URL) async throws -> Data {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached as Data
        }

        let file = fileURL(for: url)
        if let data = try? Data(contentsOf: file), !data.isEmpty {
            store(data, for: url, writeToDisk: false)
            return data
        }

        if let existing = inFlight[url] {
            return try await existing.value
        }

        let client = httpClient
        let task = Task { try await client.data(from: url) }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let data = try await task.value
        store(data, for: url, writeToDisk: true)
        return data
    }

    /// Exposed for tests: where a URL's file would live.
    func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }

    private func store(_ data: Data, for url: URL, writeToDisk: Bool) {
        memory.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        guard writeToDisk else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: url), options: .atomic)
        } catch {
            // Disk write is best-effort; the image is still in memory.
        }
    }
}
