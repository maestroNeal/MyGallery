//
//  CachedImageView.swift
//  MyGallery
//

import SwiftUI
import UIKit

/// Shows a photo using ImageService (which checks the database before downloading).
/// Shows a spinner while loading and a Retry button if loading fails.
struct CachedImageView: View {
    let image: GalleryImage
    let size: ImageSize
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var didFail = false
    @State private var retryCount = 0

    var body: some View {
        ZStack {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if didFail {
                AppColors.cardBackground
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title2)
                    Button("Retry") { retryCount += 1 }
                        .font(.caption)
                }
                .foregroundStyle(AppColors.secondaryText)
            } else {
                AppColors.cardBackground
                ProgressView()
            }
        }
        .task(id: retryCount) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard loadedImage == nil else { return }
        didFail = false
        do {
            loadedImage = try await ImageService.shared.loadImage(for: image, size: size)
        } catch {
            // If the view scrolled off screen the task is cancelled; that's not a real failure.
            if !Task.isCancelled {
                didFail = true
            }
        }
    }
}
