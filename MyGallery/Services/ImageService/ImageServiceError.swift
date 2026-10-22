//
//  ImageServiceError.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation

enum ImageServiceError: LocalizedError {
    case badURL
    case badServerResponse
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .badURL: return "The image address is not valid."
        case .badServerResponse: return "The server returned an error. Please try again."
        case .invalidImageData: return "The downloaded file is not a valid image."
        }
    }
}
