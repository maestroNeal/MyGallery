//
//  AuthUser.swift
//  MyGallery
//

import Foundation

struct AuthUser: Equatable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: URL?
}
