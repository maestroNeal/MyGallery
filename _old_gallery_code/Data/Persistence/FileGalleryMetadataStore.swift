//
//  FileGalleryMetadataStore.swift
//  MyGallery
//

import Foundation

/// Stores each gallery page as a small JSON file in Application Support.
/// The metadata is a flat list of value types, so JSON files are simpler than
/// adding a new Core Data entity and keep the data available offline.
actor FileGalleryMetadataStore: GalleryMetadataStoreProtocol {
    private let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.directory = directory ?? base.appendingPathComponent("GalleryMetadata", isDirectory: true)
    }

    func save(_ images: [GalleryImage], page: Int) {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(images)
            try data.write(to: fileURL(for: page), options: .atomic)
        } catch {
            // Caching is best-effort; a failed write must not break the gallery.
        }
    }

    func load(page: Int) -> [GalleryImage]? {
        guard let data = try? Data(contentsOf: fileURL(for: page)) else { return nil }
        return try? JSONDecoder().decode([GalleryImage].self, from: data)
    }

    private func fileURL(for page: Int) -> URL {
        directory.appendingPathComponent("page-\(page).json")
    }
}
