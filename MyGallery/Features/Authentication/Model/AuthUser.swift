//
//  AuthUser.swift
//  MyGallery
//

import Foundation

struct AuthUser: Equatable, Codable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: URL?
}
