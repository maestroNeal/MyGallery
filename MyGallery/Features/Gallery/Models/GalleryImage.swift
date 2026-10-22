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
    let url: String          // Picsum page for the photo
    let downloadURL: String  // Full-size original image

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }

    /// Width divided by height. Falls back to a square if the API sends bad sizes.
    var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }

    /// The address to download this photo at the given size.
    /// We use smaller versions instead of the original (which can be 5000px wide).
    func imageURL(for size: ImageSize) -> URL? {
        switch size {
        case .thumbnail:
            return URL(string: "https://picsum.photos/id/\(id)/400/400")
        case .detail:
            let detailWidth = 1200
            let detailHeight = max(1, Int(CGFloat(detailWidth) / aspectRatio))
            return URL(string: "https://picsum.photos/id/\(id)/\(detailWidth)/\(detailHeight)")
        }
    }
}

/// Which version of a photo we need.
nonisolated enum ImageSize: String {
    case thumbnail   // square image for the grid
    case detail      // larger image for the detail screen
}
