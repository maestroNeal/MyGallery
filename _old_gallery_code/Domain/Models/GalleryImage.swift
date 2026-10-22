//
//  GalleryImage.swift
//  MyGallery
//

import Foundation

/// A single photo in the gallery. Decoded from the Picsum `/v2/list` API.
nonisolated struct GalleryImage: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: URL?
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }

    /// Width / height of the original photo. Falls back to 1 for bad data.
    var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }

    /// Small square thumbnail so grid downloads stay light.
    var thumbnailURL: URL {
        URL(string: "https://picsum.photos/id/\(id)/400/400") ?? downloadURL
    }

    /// Screen-sized image for the detail screen (original files can be 5000px+).
    var detailURL: URL {
        let targetWidth = 1200
        let targetHeight = max(1, Int((CGFloat(targetWidth) / aspectRatio).rounded()))
        return URL(string: "https://picsum.photos/id/\(id)/\(targetWidth)/\(targetHeight)") ?? downloadURL
    }
}
