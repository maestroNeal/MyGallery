//
//  GalleryLogoView.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

struct GalleryLogoView: View {
    var size: CGFloat = 230

    private var scale: CGFloat {
        size / 230
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.07))
                .frame(width: 230, height: 230)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 175)
                .rotationEffect(.degrees(12))
                .offset(x: 24, y: 5)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 175)
                .rotationEffect(.degrees(-10))
                .offset(x: -20, y: 4)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.48),
                            Color(red: 1.0, green: 0.72, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 185)
                .shadow(
                    color: .black.opacity(0.10),
                    radius: 18,
                    y: 8
                )
                .overlay {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 68, weight: .light))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue, .cyan)
                }
                .rotationEffect(.degrees(-3))
        }
        .frame(width: 230, height: 230)
        .scaleEffect(scale)
        .frame(height: size)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
