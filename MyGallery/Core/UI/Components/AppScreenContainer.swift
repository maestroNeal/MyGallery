//
//  AppScreenContainer.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

struct AppScreenContainer<Content: View>: View {
    private let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            content
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
        }
    }
}
