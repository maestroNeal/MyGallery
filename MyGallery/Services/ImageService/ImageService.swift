//
//  ImageService.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation
import UIKit



@MainActor
final class ImageService {
    static let shared = ImageService()

    private let photoStore = PhotoStore()

    private let memoryCache = NSCache<NSString, UIImage>()

    private var downloadsInProgress: [String: Task<UIImage, Error>] = [:]

    // MARK: - Clear data
    func clearAllData() {
        for download in downloadsInProgress.values {
            download.cancel()
        }
        downloadsInProgress.removeAll()

        memoryCache.removeAllObjects()
        photoStore.deleteAllPhotos()
        URLCache.shared.removeAllCachedResponses()
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
            print("[Gallery] Page \(page): loaded \(images.count) photos from the API")
            return images
        } catch {
            // No internet (or bad response): show this page from the database if we saved it before.
            let savedImages = photoStore.loadPhotos(page: page)
            if !savedImages.isEmpty {
                print("[Gallery] Page \(page): no internet, loaded \(savedImages.count) photos from Core Data")
                return savedImages
            }
            throw error
        }
    }

    // MARK: - Image files
    func loadImage(for image: GalleryImage) async throws -> UIImage {
        let key = image.id

        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            print("Already in memory")
            return cachedImage
        }

        if let savedData = photoStore.imageData(photoID: image.id),
           let savedImage = UIImage(data: savedData) {
            memoryCache.setObject(savedImage, forKey: key as NSString)
            print("Saved in the database? Use it, no network needed")
            return savedImage
        }

        if let existingDownload = downloadsInProgress[key] {
            print("Someone is already downloading it? Wait for that download")
            return try await existingDownload.value
        }

        guard let url = image.imageURL else {
            print(ImageServiceError.badURL.errorDescription)
            throw ImageServiceError.badURL
        }

        print("Download it, save it in the database, and return it.")
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
