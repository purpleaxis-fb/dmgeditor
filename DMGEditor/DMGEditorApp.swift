//
//  DMGEditorApp.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

import SwiftUI

@main
struct DMGEditorApp: App {
    
    @StateObject private var alertManager = AlertManager()
    
    var body: some Scene {
        WindowGroup {
            DMGEditorView()
                .environmentObject(alertManager)
        }
    }
}