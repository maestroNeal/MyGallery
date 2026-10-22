//
//  PhotoStore.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import CoreData

final class PhotoStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Photo details

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

    func loadPhotos(page: Int) -> [GalleryImage] {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "page == %d", page)
        request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]

        let photos = (try? context.fetch(request)) ?? []
        return photos.compactMap { $0.toGalleryImage() }
    }

    // MARK: - Image bytes
    /// Returns the saved image bytes, or nil if this photo was never downloaded.
    func imageData(photoID: String) -> Data? {
        findPhoto(id: photoID)?.imageData
    }

    func saveImageData(_ data: Data, photoID: String) {
        guard let photo = findPhoto(id: photoID) else { return }
        photo.imageData = data
        saveChanges()
    }

    private func findPhoto(id: String) -> Photo? {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.predicate = NSPredicate(format: "photoID == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Deletes every saved photo (details and image bytes). Used on logout.
    func deleteAllPhotos() {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        let photos = (try? context.fetch(request)) ?? []
        for photo in photos {
            context.delete(photo)
        }
        saveChanges()
    }

    private func saveChanges() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            print("Could not save photos: \(error)")
        }
    }
}

private extension Photo {
    // Converts a Core Data row back into the model 
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
