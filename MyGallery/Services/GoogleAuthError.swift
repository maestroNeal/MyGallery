//
//  GoogleAuthError.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

enum GoogleAuthError: LocalizedError {
    case missingClientID
    case noPresentingViewController
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Firebase client ID is missing."
        case .noPresentingViewController:
            return "Unable to open Google Sign-In."
        case .missingIDToken:
            return "Google did not return an ID token."
        }
    }
}
