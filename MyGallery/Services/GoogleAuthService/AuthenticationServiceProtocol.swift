//
//  AuthenticationServiceProtocol.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation

@MainActor
protocol AuthenticationServiceProtocol {
    func signIn() async throws -> AuthUser
    func restorePreviousSignIn() async -> AuthUser?
    func signOut() async throws
    func handle(url: URL) -> Bool
}
