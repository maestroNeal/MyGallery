//
//  AppColors.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

enum AppColors {
    static let background = Color(uiColor: .systemBackground)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let cardBackground = Color(uiColor: .secondarySystemBackground)
    static let separator = Color(uiColor: .separator)
    static let accent = Color.accentColor
}

enum AppTypography {
    static let title = Font.system(
        .largeTitle,
        design: .rounded,
        weight: .bold
    )

    static let subtitle = Font.body

    static let button = Font.headline

    static let caption = Font.footnote
}

