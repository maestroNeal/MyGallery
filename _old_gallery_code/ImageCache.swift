//
//  ImageCache.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation
import UIKit

/// Saves downloaded images (and photo-list pages) as files on the device.
///
/// - Memory cache (NSCache): makes scrolling back up instant.
/// - Disk cache (FileManager, Caches folder): survives app restarts, so images
///   that were already downloaded can be shown without a network connection.
///
/// iOS may clear the Caches folder when storage is low; the app then simply
/// downloads the image again.
final class ImageCache {
    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let folder: URL

    init() {
        let cachesFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        folder = cachesFolder.appendingPathComponent("GalleryImages", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        memoryCache.countLimit = 200
    }

    // MARK: - Images

    func image(for url: URL) -> UIImage? {
        if let image = memoryCache.object(forKey: url as NSURL) {
            return image
        }

        let file = fileURL(for: url)
        guard let data = try? Data(contentsOf: file) else {
            return nil   // not saved yet
        }
        guard let image = UIImage(data: data) else {
            try? fileManager.removeItem(at: file)   // corrupted file: delete it and download again
            return nil
        }

        memoryCache.setObject(image, forKey: url as NSURL)
        return image
    }

    func save(_ data: Data, image: UIImage, for url: URL) {
        memoryCache.setObject(image, forKey: url as NSURL)
        try? data.write(to: fileURL(for: url), options: .atomic)
    }

    // MARK: - Photo list pages

    func savePageData(_ data: Data, page: Int) {
        try? data.write(to: folder.appendingPathComponent("page-\(page).json"), options: .atomic)
    }

    func loadPageData(page: Int) -> Data? {
        try? Data(contentsOf: folder.appendingPathComponent("page-\(page).json"))
    }

    // MARK: - File names

    /// A stable file name built from the image address.
    /// Example: https://picsum.photos/id/10/400/400  ->  "id_10_400_400.jpg"
    private func fileURL(for url: URL) -> URL {
        let name = url.path
            .split(separator: "/")
            .joined(separator: "_")
        return folder.appendingPathComponent(name.isEmpty ? "image" : name + ".jpg")
    }
}
