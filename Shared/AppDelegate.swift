//
//  AppDelegate.swift
//  Images
//
//  Created by Jakub Charvat on 24.11.2020.
//

import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillUpdate(_ notification: Notification) {
        (notification.object as? NSApplication)?.windows.forEach { window in
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
//            window.isMovableByWindowBackground = true
        }
    }
}
