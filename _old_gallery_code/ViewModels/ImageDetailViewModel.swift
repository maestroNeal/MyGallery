//
//  ImageDetailViewModel.swift
//  MyGallery
//

import Foundation

/// Prepares the selected image's data for display. Holds no network code;
/// the image itself is loaded through the shared image cache.
@MainActor
final class ImageDetailViewModel {
    let image: GalleryImage

    init(image: GalleryImage) {
        self.image = image
    }

    var title: String { image.author }
    var imageURL: URL { image.detailURL }
    var aspectRatio: CGFloat { image.aspectRatio }

    var metadata: [(label: String, value: String)] {
        [
            ("Author", image.author),
            ("Image ID", image.id),
            ("Original size", "\(image.width) × \(image.height)")
        ]
    }

    var sourceURL: URL? { image.url }
}
