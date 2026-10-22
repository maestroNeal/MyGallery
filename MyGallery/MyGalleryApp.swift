//
//  MyGalleryApp.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI
import CoreData

@main
struct MyGalleryApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authViewModel = AuthViewModel(
        authenticationService: GoogleAuthService()
    )

    init() {
        NetworkMonitor.shared.startMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: authViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    authViewModel.handle(url: url)
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        Group {
            if viewModel.isRestoring {
                ProgressView()
            } else if viewModel.isAuthenticated {
                GalleryView(onLogout: {
                    Task { await viewModel.signOut() }
                })
            } else {
                LoginView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    onGoogleSignIn: {
                        Task { await viewModel.signIn() }
                    }
                )
            }
        }
        .animation(.default, value: viewModel.isAuthenticated)
        .task {
            await viewModel.restoreSession()
        }
    }
}
