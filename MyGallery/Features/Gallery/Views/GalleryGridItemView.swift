//
//  GalleryGridItemView.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

/// One card in the grid. The image is always square and the author is one line,
/// so every card has exactly the same height.
struct GalleryGridItemView: View {
    let image: GalleryImage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    CachedImageView(image: image, contentMode: .fill)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(image.author)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo by \(image.author)")
    }
}
