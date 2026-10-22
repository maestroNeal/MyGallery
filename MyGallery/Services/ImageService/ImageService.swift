//
//  ImageService.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation
import UIKit


final class ImageService {
    static let shared = ImageService()

    private let photoStore = PhotoStore()

    private let memoryCache = NSCache<NSString, UIImage>()

    private var downloadsInProgress: [String: Task<UIImage, Error>] = [:]

    // MARK: - Clear data

    /// Removes everything saved on the device for the gallery. Called on logout.
    func clearAllData() {
        // Stop downloads that are still running so they don't save anything afterwards.
        for download in downloadsInProgress.values {
            download.cancel()
        }
        downloadsInProgress.removeAll()

        memoryCache.removeAllObjects()                 // images in memory
        photoStore.deleteAllPhotos()                   // photos saved in Core Data
        URLCache.shared.removeAllCachedResponses()     // URLSession's own HTTP cache
    }

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

    /// Returns the photo's image. The network is used ONLY if the image is not
    /// already in memory or saved in Core Data.
    func loadImage(for image: GalleryImage) async throws -> UIImage {
        let key = image.id

        // 1. Already in memory?
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }

        // 2. Saved in the database? Use it, no network needed.
        if let savedData = photoStore.imageData(photoID: image.id),
           let savedImage = UIImage(data: savedData) {
            memoryCache.setObject(savedImage, forKey: key as NSString)
            return savedImage
        }

        // 3. Someone is already downloading it? Wait for that download.
        if let existingDownload = downloadsInProgress[key] {
            return try await existingDownload.value
        }

        // 4. Download it, save it in the database, and return it.
        guard let url = image.imageURL else {
            throw ImageServiceError.badURL
        }

        let download = Task { () throws -> UIImage in
            let data = try await downloadData(from: url)
            guard let downloadedImage = UIImage(data: data) else {
                throw ImageServiceError.invalidImageData
            }
            photoStore.saveImageData(data, photoID: image.id)
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
