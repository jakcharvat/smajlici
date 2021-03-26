//
//  ImagesApp.swift
//  Images
//
//  Created by Jakub Charvat on 22.11.2020.
//

import SwiftUI
import Combine


@main
struct ImagesApp: App {
    @State private var showingPredictionView = false
    @StateObject private var keystrokes = Keystrokes()
    @NSApplicationDelegateAdaptor var delegate: AppDelegate
    
    @Namespace var namespace
    
    var body: some Scene {
        WindowGroup {
            ClassificationView()
                .macosMinimumWindowSize()
                .environmentObject(keystrokes)
        }
        .commands {
            CommandMenu("Classification") {
                Button("Smajlík") {
                    keystrokes.sendKey(.s)
                }
                .disabled(!keystrokes.enabled)
                .keyboardShortcut(.init("s"))
                
                Button("Mračoun") {
                    keystrokes.sendKey(.m)
                }
                .disabled(!keystrokes.enabled)
                .keyboardShortcut(.init("m"))
            }
        }
    }
}


//MARK: - Keystrokes
class Keystrokes: ObservableObject {
    let publisher = PassthroughSubject<Key, Never>()
    @Published var enabled = false
    
    func sendKey(_ key: Key) {
        publisher.send(key)
    }
    
    enum Key {
        case s, m
    }
}


//MARK: - Frame
fileprivate extension View {
    func macosMinimumWindowSize() -> some View {
        #if os(macOS)
        return frame(width: 600, height: 500)
        #else
        return self
        #endif
    }
}
