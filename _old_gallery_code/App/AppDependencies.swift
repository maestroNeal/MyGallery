//
//  AppDependencies.swift
//  MyGallery
//

import Foundation

/// Composition root: builds the real services, or test doubles when the app
/// is launched by UI tests with `-uiTesting`.
@MainActor
struct AppDependencies {
    let authService: AuthenticationServiceProtocol
    let imageRepository: ImageRepositoryProtocol
    let imageCache: any ImageCacheProtocol

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        #if DEBUG
        if arguments.contains("-uiTesting") {
            return AppDependencies(
                authService: UITestAuthService(),
                imageRepository: UITestImageRepository(),
                imageCache: UITestImageCache()
            )
        }
        #endif
        return AppDependencies(
            authService: GoogleAuthService(),
            imageRepository: DefaultImageRepository(),
            imageCache: DiskImageCache.shared
        )
    }
}
