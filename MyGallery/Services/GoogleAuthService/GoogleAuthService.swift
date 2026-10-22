//
//  GoogleAuthService.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class GoogleAuthService: AuthenticationServiceProtocol {

    init() {
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            print("Configured")
        } else {
            print("ERROR: GIDClientID is missing")
        }
    }

    func signIn() async throws -> AuthUser {
        print("Starting sign-in")
        guard GIDSignIn.sharedInstance.configuration != nil else {
            print("ERROR: not configured")
            throw GoogleAuthError.missingClientID
        }
        guard let presenter = UIApplication.shared.topViewController else {
            print("ERROR: no screen found to show the Google sign-in sheet")
            throw GoogleAuthError.noPresentingViewController
        }

        print("Showing Google account picker")
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == kGIDSignInErrorDomain,
                       nsError.code == GIDSignInError.canceled.rawValue {
                        print("User cancelled sign-in")
                        continuation.resume(throwing: GoogleAuthError.cancelled)
                    } else {
                        print("Sign-in failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let user = result?.user else {
                    print("Sign-in failed: Google returned no user")
                    continuation.resume(throwing: GoogleAuthError.noUser)
                    return
                }
                let signedInUser = Self.makeUser(from: user)
                print("Sign-in successful: \(signedInUser.name) (\(signedInUser.email))")
                continuation.resume(returning: signedInUser)
            }
        }
    }

    func restorePreviousSignIn() async -> AuthUser? {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else {
            print("No previous Google session to restore")
            return nil
        }
        print("Restoring previous Google session")
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let user {
                    print("Session restored for \(user.profile?.email ?? "unknown email")")
                } else {
                    print("Could not restore session: \(error?.localizedDescription ?? "unknown error")")
                }
                continuation.resume(returning: user.map(Self.makeUser(from:)))
            }
        }
    }

    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        print("Signed out from Google")
    }

    func handle(url: URL) -> Bool {
        let handled = GIDSignIn.sharedInstance.handle(url)
        print("Received callback URL, handled by Google: \(handled)")
        return handled
    }

    private static func makeUser(from user: GIDGoogleUser) -> AuthUser {
        let profile = user.profile
        return AuthUser(
            id: user.userID ?? "",
            name: profile?.name ?? "",
            email: profile?.email ?? "",
            profileImageURL: (profile?.hasImage ?? false)
                ? profile?.imageURL(withDimension: 200)
                : nil
        )
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
        return window?.rootViewController?.topMostViewController
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostViewController
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostViewController
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController
        }
        return self
    }
}
