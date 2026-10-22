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
        // GIDSignIn reads GIDClientID from Info.plist automatically;
        // set it explicitly too so a missing key fails with a clear error.
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    func signIn() async throws -> AuthUser {
        guard GIDSignIn.sharedInstance.configuration != nil else {
            throw GoogleAuthError.missingClientID
        }
        guard let presenter = UIApplication.shared.topViewController else {
            throw GoogleAuthError.noPresentingViewController
        }

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == kGIDSignInErrorDomain,
                       nsError.code == GIDSignInError.canceled.rawValue {
                        continuation.resume(throwing: GoogleAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let user = result?.user else {
                    continuation.resume(throwing: GoogleAuthError.noUser)
                    return
                }
                continuation.resume(returning: Self.makeUser(from: user))
            }
        }
    }

    func restorePreviousSignIn() async -> AuthUser? {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return nil }
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, _ in
                continuation.resume(returning: user.map(Self.makeUser(from:)))
            }
        }
    }

    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
    }

    func handle(url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
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
