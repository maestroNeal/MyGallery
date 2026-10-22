//
//  GoogleAuthError.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation

enum GoogleAuthError: LocalizedError {
    case missingClientID
    case noPresentingViewController
    case cancelled
    case noUser

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Google client ID (GIDClientID) is missing from Info.plist."
        case .noPresentingViewController:
            return "Unable to open Google Sign-In."
        case .cancelled:
            return "Sign-in was cancelled."
        case .noUser:
            return "Google did not return a user."
        }
    }
}
