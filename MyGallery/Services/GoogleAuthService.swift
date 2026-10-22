//
//  GoogleAuthService.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//


import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

@MainActor
final class GoogleAuthService: AuthenticationServiceProtocol {

    func signIn() async throws {
      
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleAuthError.missingClientID
        }

        guard let presentingViewController =
                UIApplication.shared.topViewController else {
            throw GoogleAuthError.noPresentingViewController
        }

        GIDSignIn.sharedInstance.configuration =
            GIDConfiguration(clientID: clientID)

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleAuthError.missingIDToken
        }

        let accessToken = result.user.accessToken.tokenString

        // 6. Exchange Google tokens for a Firebase credential
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        _ = try await Auth.auth().signIn(with: credential)
    }

    func signOut() async throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
}


private extension UIApplication {
    var topViewController: UIViewController? {
        let scenes = connectedScenes
            .compactMap { $0 as? UIWindowScene }

        guard let windowScene = scenes.first(where: {
            $0.activationState == .foregroundActive
        }),
        let root = windowScene.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            return nil
        }

        return root.topViewController
    }
}

private extension UIViewController {
    var topViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topViewController
        }

        if let navigationController = self as? UINavigationController,
           let visible = navigationController.visibleViewController {
            return visible.topViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selected = tabBarController.selectedViewController {
            return selected.topViewController
        }

        return self
    }
}
