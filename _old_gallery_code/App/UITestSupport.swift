//
//  UITestSupport.swift
//  MyGallery
//
//  Test doubles used only when UI tests launch the app with `-uiTesting`.
//  They let UI tests run without a Google account or network access.
//

#if DEBUG
import Foundation
import UIKit

@MainActor
final class UITestAuthService: AuthenticationServiceProtocol {
    func signIn() async throws -> AuthUser {
        AuthUser(id: "ui-test", name: "UI Test User", email: "uitest@example.com", profileImageURL: nil)
    }

    func restorePreviousSignIn() async -> AuthUser? { nil }
    func signOut() async throws {}
    func handle(url: URL) -> Bool { false }
}

nonisolated struct UITestImageRepository: ImageRepositoryProtocol {
    func fetchImages(page: Int, limit: Int) async throws -> [GalleryImage] {
        guard page == 1 else { return [] }
        let sizes = [(5000, 3333), (3000, 4000), (2000, 2000), (4000, 2000), (1080, 1920), (2500, 1667)]
        return (0..<12).map { index in
            let size = sizes[index % sizes.count]
            return GalleryImage(
                id: "\(index)",
                author: "Test Author \(index)",
                width: size.0,
                height: size.1,
                url: nil,
                downloadURL: URL(string: "https://example.com/\(index).jpg")!
            )
        }
    }
}

/// Renders a solid-colour PNG locally instead of downloading.
nonisolated struct UITestImageCache: ImageCacheProtocol {
    func data(for url: URL) async throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        return image.pngData() ?? Data()
    }
}
#endif
