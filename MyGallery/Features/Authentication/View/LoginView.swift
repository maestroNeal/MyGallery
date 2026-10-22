//
//  LoginView.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI


struct LoginView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let isLoading: Bool
    let errorMessage: String?
    let onGoogleSignIn: () -> Void

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        AppScreenContainer {
            //ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: isRegularWidth ? 48 : 24)

                    GalleryLogoView(size: 200)
                        .frame(
                            height: isRegularWidth ? 270 : 220
                        )

                    VStack(spacing: 14) {
                        Text("Welcome to\nMy Gallery")
                            .font(AppTypography.title)
                            .foregroundStyle(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                            .accessibilityAddTraits(.isHeader)

                        Text(
                            "Discover beautiful wallpapers and save " +
                            "your favorites. Sign in to get started."
                        )
                        .font(AppTypography.subtitle)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        GoogleSignInButton(
                            isLoading: isLoading,
                            action: onGoogleSignIn
                        )

                        if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.updatesFrequently)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)

                    Spacer(minLength: 48)

                    VStack(spacing: 6) {
                        Text("Your personal gallery,")
                        Text("wherever you go.")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 500)
           // }
           // .scrollIndicators(.hidden)
        }
    }
}

#Preview("Light") {
    LoginView(
        isLoading: false,
        errorMessage: nil,
        onGoogleSignIn: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView(
        isLoading: false,
        errorMessage: nil,
        onGoogleSignIn: {}
    )
    .preferredColorScheme(.dark)
}

