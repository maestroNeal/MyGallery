//
//  DeviceLayout.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

enum DeviceLayout {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
