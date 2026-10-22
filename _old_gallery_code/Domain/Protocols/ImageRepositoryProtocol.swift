//
//  ImageRepositoryProtocol.swift
//  MyGallery
//

import Foundation

nonisolated protocol ImageRepositoryProtocol: Sendable {
    /// Returns one page of images. `page` is 1-based.
    func fetchImages(page: Int, limit: Int) async throws -> [GalleryImage]
}

/// Loads raw image bytes, using memory + disk caching.
nonisolated protocol ImageCacheProtocol: Sendable {
    func data(for url: URL) async throws -> Data
}

/// Persists gallery metadata so the last loaded pages are available offline.
nonisolated protocol GalleryMetadataStoreProtocol: Sendable {
    func save(_ images: [GalleryImage], page: Int) async
    func load(page: Int) async -> [GalleryImage]?
}
