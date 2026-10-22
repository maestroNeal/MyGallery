//
//  UserSessionStore.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation

final class UserSessionStore {
    private let defaults = UserDefaults.standard
    private let userKey = "signedInUser"

    func save(_ user: AuthUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        defaults.set(data, forKey: userKey)
    }

    func loadUser() -> AuthUser? {
        guard let data = defaults.data(forKey: userKey) else { return nil }
        guard let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            defaults.removeObject(forKey: userKey)   // old or broken data: start fresh
            return nil
        }
        return user
    }

    func clear() {
        defaults.removeObject(forKey: userKey)
    }
}
