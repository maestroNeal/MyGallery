//
//  AuthViewModel.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI
import Combine

@MainActor
protocol AuthenticationServiceProtocol {
    func signIn() async throws -> AuthUser
    func restorePreviousSignIn() async -> AuthUser?
    func signOut() async throws
    func handle(url: URL) -> Bool
}

/// Single source of truth for authentication state.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isLoading = false
    @Published private(set) var isRestoring = true
    @Published private(set) var errorMessage: String?

    var isAuthenticated: Bool { user != nil }

    private let authenticationService: AuthenticationServiceProtocol
    private let sessionStore = UserSessionStore()

    init(authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
    }

    /// Runs once when the app starts.
    func restoreSession() async {
        guard isRestoring else { return }

        // No saved user (first launch, after logout, or after reinstalling the app):
        // clear any old Google session left in the Keychain and show the login screen.
        guard let savedUser = sessionStore.loadUser() else {
            try? await authenticationService.signOut()
            user = nil
            isRestoring = false
            return
        }

        // A saved user exists: open the gallery straight away, even without internet.
        user = savedUser
        isRestoring = false

        // Also refresh the Google session in the background to get the latest
        // name and photo. If it fails (for example, offline) the user stays logged in.
        if let refreshedUser = await authenticationService.restorePreviousSignIn() {
            user = refreshedUser
            sessionStore.save(refreshedUser)
        }
    }

    func signIn() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let signedInUser = try await authenticationService.signIn()
            user = signedInUser
            sessionStore.save(signedInUser)
        } catch GoogleAuthError.cancelled {
            errorMessage = "Sign-in was cancelled."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await authenticationService.signOut()
        } catch {
            // Local UI state is still cleared so the user is never stuck signed in.
        }
        sessionStore.clear()                 // saved user in UserDefaults
        ImageService.shared.clearAllData()   // saved photos and images
        user = nil
        errorMessage = nil
    }

    func handle(url: URL) {
        _ = authenticationService.handle(url: url)
    }
}
