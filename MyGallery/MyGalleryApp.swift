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
            } else if let user = viewModel.user {
                ProfileView(user: user, onSignOut: viewModel.signOut)
            } else {
                LoginView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    onGoogleSignIn: viewModel.signIn
                )
            }
        }
        .task { await viewModel.restoreSession() }
    }
}
