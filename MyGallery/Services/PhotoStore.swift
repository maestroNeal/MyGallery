//
//  PhotoStore.swift
//  MyGallery
//

import CoreData

/// Saves and reads photos in Core Data, so the gallery works without internet.
///
/// Each `Photo` row stores:
/// - the photo details from the API (id, author, size, URLs)
/// - which page it came from and its position in that page (to keep the order)
/// - the downloaded image bytes (thumbnail for the grid, larger image for the detail screen)
final class PhotoStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Photo details

    /// Saves one page of photos. Photos that already exist are updated, not duplicated,
    /// and their saved image bytes are kept.
    func savePhotos(_ images: [GalleryImage], page: Int) {
        for (position, image) in images.enumerated() {
            let photo = findPhoto(id: image.id) ?? Photo(context: context)
            photo.photoID = image.id
            photo.author = image.author
            photo.width = Int64(image.width)
            photo.height = Int64(image.height)
            photo.pageURL = image.url
            photo.downloadURL = image.downloadURL
            photo.page = Int64(page)
            photo.position = Int64(position)
        }
        saveChanges()
    }

    /// Returns the saved photos of one page, in the same order as the API.
    func loadPhotos(page: Int) -> [GalleryImage] {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "page == %d", page)
        request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]

        let photos = (try? context.fetch(request)) ?? []
        return photos.compactMap { $0.toGalleryImage() }
    }

    // MARK: - Image bytes

    func imageData(photoID: String, size: ImageSize) -> Data? {
        guard let photo = findPhoto(id: photoID) else { return nil }
        switch size {
        case .thumbnail: return photo.thumbnailData
        case .detail: return photo.detailImageData
        }
    }

    func saveImageData(_ data: Data, photoID: String, size: ImageSize) {
        guard let photo = findPhoto(id: photoID) else { return }
        switch size {
        case .thumbnail: photo.thumbnailData = data
        case .detail: photo.detailImageData = data
        }
        saveChanges()
    }

    // MARK: - Helpers

    private func findPhoto(id: String) -> Photo? {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "photoID == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func saveChanges() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // Saving is only for offline use; the app keeps working if it fails.
            context.rollback()
            print("Could not save photos: \(error)")
        }
    }
}

private extension Photo {
    /// Converts a Core Data row back into the model the screens use.
    func toGalleryImage() -> GalleryImage? {
        guard let photoID else { return nil }
        return GalleryImage(
            id: photoID,
            author: author ?? "Unknown",
            width: Int(width),
            height: Int(height),
            url: pageURL ?? "",
            downloadURL: downloadURL ?? ""
        )
    }
}
