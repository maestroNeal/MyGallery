//
//  GalleryImage.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation

/// One photo from the Picsum API (https://picsum.photos/v2/list).
nonisolated struct GalleryImage: Identifiable, Hashable, Codable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }

    /// Width divided by height. Falls back to a square if the API sends bad sizes.
    var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }

    /// The one image we download for this photo, used by both the grid and the
    /// detail screen. It keeps the original aspect ratio but is much smaller
    /// than the original file (which can be 5000px wide).
    var imageURL: URL? {
        let imageWidth = 1000
        let imageHeight = max(1, Int(CGFloat(imageWidth) / aspectRatio))
        return URL(string: "https://picsum.photos/id/\(id)/\(imageWidth)/\(imageHeight)")
    }
}
