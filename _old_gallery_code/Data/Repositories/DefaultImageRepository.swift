//
//  DefaultImageRepository.swift
//  MyGallery
//

import Foundation

/// Fetches gallery pages from Picsum. Successful pages are saved to the
/// metadata store; when the network fails, the saved page is returned instead.
nonisolated struct DefaultImageRepository: ImageRepositoryProtocol {
    private let apiClient: APIClient
    private let metadataStore: GalleryMetadataStoreProtocol
    private let baseURL: URL

    init(
        apiClient: APIClient = APIClient(),
        metadataStore: GalleryMetadataStoreProtocol = FileGalleryMetadataStore(),
        baseURL: URL = URL(string: "https://picsum.photos/v2/list")!
    ) {
        self.apiClient = apiClient
        self.metadataStore = metadataStore
        self.baseURL = baseURL
    }

    func fetchImages(page: Int, limit: Int) async throws -> [GalleryImage] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components?.url else { throw APIError.invalidResponse }

        do {
            let images = try await apiClient.get([GalleryImage].self, from: url)
            await metadataStore.save(images, page: page)
            return images
        } catch {
            if let cached = await metadataStore.load(page: page) {
                return cached
            }
            throw error
        }
    }
}
