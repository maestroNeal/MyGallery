//
//  ImageCacheEnvironment.swift
//  MyGallery
//

import SwiftUI
import UIKit

/// Lets views get the image cache through dependency injection.
nonisolated private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: any ImageCacheProtocol = DiskImageCache.shared
}

extension EnvironmentValues {
    var imageCache: any ImageCacheProtocol {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}

/// Decoded UIImages, checked synchronously so scrolling back to a cell
/// shows the image immediately instead of flashing a placeholder.
enum DecodedImageMemoryCache {
    private static let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 300
        return cache
    }()

    static func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
