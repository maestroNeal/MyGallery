//
//  ImageDetailView.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

struct ImageDetailView: View {
    let image: GalleryImage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Color.clear
                    .aspectRatio(image.aspectRatio, contentMode: .fit)
                    .overlay {
                        CachedImageView(image: image, size: .detail, contentMode: .fit)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Photo by \(image.author)")

                VStack(alignment: .leading, spacing: 0) {
                    infoRow(title: "Author", value: image.author)
                    Divider()
                    infoRow(title: "Image ID", value: image.id)
                    Divider()
                    infoRow(title: "Original size", value: "\(image.width) × \(image.height)")
                    Divider()
                    infoRow(title: "Image URL", value: image.downloadURL)
                }
                .padding(.horizontal, 16)
                .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14))

                if let pageURL = URL(string: image.url) {
                    Link(destination: pageURL) {
                        Label("Open photo page", systemImage: "safari")
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
        }
        .background(AppColors.background)
        .navigationTitle(image.author)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}
