//
//  BlurView.swift
//  Images
//
//  Created by Jakub Charvat on 24.11.2020.
//

import SwiftUI


struct BlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .sidebar
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}
