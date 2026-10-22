//
//  AuthViewMOdel.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//


protocol AuthenticationServiceProtocol {
    func signIn() async throws
    func signOut() async throws
}

import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let authenticationService: AuthenticationServiceProtocol

    init(authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
    }

    func signIn() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }

            do {
                try await authenticationService.signIn()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
