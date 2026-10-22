//
//  GalleryViewModel.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Combine
import Foundation

/// Holds the gallery's data and state. The view only reads these values
/// and calls these functions; it never talks to the network itself.
@MainActor
final class GalleryViewModel: ObservableObject {
    @Published private(set) var images: [GalleryImage] = []
    @Published private(set) var isLoading = false        // first page
    @Published private(set) var isLoadingMore = false    // next pages
    @Published private(set) var errorMessage: String?
    @Published private(set) var loadMoreErrorMessage: String?

    private let imageService = ImageService.shared
    private let pageSize = 20
    private var nextPage = 1
    private var hasMorePages = true

    var isEmpty: Bool {
        !isLoading && errorMessage == nil && images.isEmpty && !hasMorePages
    }

    /// Called when the screen appears. Does nothing if images are already loaded,
    /// so coming back from the detail screen keeps the same list and scroll position.
    func loadFirstPageIfNeeded() async {
        guard images.isEmpty, !isLoading else { return }
        await loadFirstPage()
    }

    func loadFirstPage() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let firstPage = try await imageService.fetchImages(page: 1, limit: pageSize)
            images = firstPage
            nextPage = 2
            hasMorePages = firstPage.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called when a card appears. Starts loading the next page when the user
    /// is close to the bottom of the list.
    func loadMoreIfNeeded(currentImage: GalleryImage) async {
        guard let index = images.firstIndex(of: currentImage),
              index >= images.count - 4 else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        // These checks stop duplicate requests while one is already running.
        guard !isLoading, !isLoadingMore, hasMorePages, !images.isEmpty else { return }

        isLoadingMore = true
        loadMoreErrorMessage = nil
        defer { isLoadingMore = false }

        do {
            let newImages = try await imageService.fetchImages(page: nextPage, limit: pageSize)
            let existingIDs = Set(images.map { $0.id })
            images += newImages.filter { !existingIDs.contains($0.id) }
            nextPage += 1
            hasMorePages = newImages.count == pageSize
        } catch {
            loadMoreErrorMessage = error.localizedDescription
        }
    }
}
