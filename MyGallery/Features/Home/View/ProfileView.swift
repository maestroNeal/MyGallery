//
//  ProfileView.swift
//  MyGallery
//

import SwiftUI

struct ProfileView: View {
    let user: AuthUser
    let onSignOut: () -> Void

    var body: some View {
        AppScreenContainer {
            VStack(spacing: 16) {
                Spacer()

                AsyncImage(url: user.profileImageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())

                Text(user.name.isEmpty ? "Signed in" : user.name)
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.primaryText)

                if !user.email.isEmpty {
                    Text(user.email)
                        .font(AppTypography.subtitle)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                Button("Sign out", role: .destructive, action: onSignOut)
                    .buttonStyle(.bordered)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }
}
