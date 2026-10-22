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

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isLoading = false
    @Published private(set) var isRestoring = true
    @Published private(set) var errorMessage: String?

    private let authenticationService: AuthenticationServiceProtocol

    init(authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
    }

    func restoreSession() async {
        user = await authenticationService.restorePreviousSignIn()
        isRestoring = false
    }

    func signIn() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                user = try await authenticationService.signIn()
            } catch GoogleAuthError.cancelled {
                // User dismissed the Google sheet: no error message.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        Task {
            try? await authenticationService.signOut()
            user = nil
        }
    }

    func handle(url: URL) {
        _ = authenticationService.handle(url: url)
    }
}
