//
//  NetworkMonitor.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()

    func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("[Network] Internet is available")
            } else {
                print("[Network] No internet connection")
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}
