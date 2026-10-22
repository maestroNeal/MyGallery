//
//  Persistence.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import CoreData

/// Sets up the Core Data database.
/// The model file (MyGallery.xcdatamodeld) has one entity: `Photo`.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        let container = NSPersistentContainer(name: "MyGallery")

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        // If the saved database was created by an older version of the model,
        // it can't be opened. It only holds cached photos, so it is safe to
        // delete it and start with an empty database.
        if loadError != nil, let storeURL = container.persistentStoreDescriptions.first?.url {
            try? container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
            container.loadPersistentStores { _, error in
                if let error {
                    print("Core Data failed to load: \(error)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        self.container = container
    }
}
