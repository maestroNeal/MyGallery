//
//  ImageService.swift
//  MyGallery
//

import Foundation
import UIKit

enum ImageServiceError: LocalizedError {
    case badURL
    case badServerResponse
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .badURL: return "The image address is not valid."
        case .badServerResponse: return "The server returned an error. Please try again."
        case .invalidImageData: return "The downloaded file is not a valid image."
        }
    }
}

/// All network work for the gallery. Everything downloaded is saved in
/// Core Data (through PhotoStore) so it can be shown later without internet.
final class ImageService {
    static let shared = ImageService()

    private let photoStore = PhotoStore()

    /// Images already turned into UIImage, kept in memory for smooth scrolling.
    private let memoryCache = NSCache<NSString, UIImage>()

    /// Downloads currently in progress, so two views asking for the same image share one download.
    private var downloadsInProgress: [String: Task<UIImage, Error>] = [:]

    // MARK: - Photo list

    func fetchImages(page: Int, limit: Int) async throws -> [GalleryImage] {
        guard let url = URL(string: "https://picsum.photos/v2/list?page=\(page)&limit=\(limit)") else {
            throw ImageServiceError.badURL
        }

        do {
            let data = try await downloadData(from: url)
            let images = try JSONDecoder().decode([GalleryImage].self, from: data)
            photoStore.savePhotos(images, page: page)
            return images
        } catch {
            // No internet (or bad response): show this page from the database if we saved it before.
            let savedImages = photoStore.loadPhotos(page: page)
            if !savedImages.isEmpty {
                return savedImages
            }
            throw error
        }
    }

    // MARK: - Image files

    func loadImage(for image: GalleryImage, size: ImageSize) async throws -> UIImage {
        let key = "\(image.id)-\(size.rawValue)"

        // 1. Already in memory?
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }

        // 2. Saved in the database? Use it, no network needed.
        if let savedData = photoStore.imageData(photoID: image.id, size: size),
           let savedImage = UIImage(data: savedData) {
            memoryCache.setObject(savedImage, forKey: key as NSString)
            return savedImage
        }

        // 3. Someone is already downloading it? Wait for that download.
        if let existingDownload = downloadsInProgress[key] {
            return try await existingDownload.value
        }

        // 4. Download it, save it in the database, and return it.
        guard let url = image.imageURL(for: size) else {
            throw ImageServiceError.badURL
        }

        let download = Task { () throws -> UIImage in
            let data = try await downloadData(from: url)
            guard let downloadedImage = UIImage(data: data) else {
                throw ImageServiceError.invalidImageData
            }
            photoStore.saveImageData(data, photoID: image.id, size: size)
            memoryCache.setObject(downloadedImage, forKey: key as NSString)
            return downloadedImage
        }

        downloadsInProgress[key] = download
        defer { downloadsInProgress[key] = nil }
        return try await download.value
    }

    // MARK: - Helpers

    private func downloadData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImageServiceError.badServerResponse
        }
        return data
    }
}
