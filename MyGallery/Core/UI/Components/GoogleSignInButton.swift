//
//  GoogleSignInButton.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else {
                    Image("GoogleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .accessibilityHidden(true)
                }

                Text(isLoading ? "Signing in..." : "Sign in with Google")
                    .font(AppTypography.button)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 16)
            .background(AppColors.background)
            .foregroundStyle(AppColors.primaryText)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColors.separator, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("Sign in with Google")
        .accessibilityHint("Signs you in to your wallpaper gallery")
    }
}
