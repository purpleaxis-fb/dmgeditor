//
//  DMGPreviewCanvas.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

// UI/DMGPreviewCanvas.swift
import SwiftUI

struct DMGPreviewCanvas: View {
    @Binding var config: DMGConfig
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            Text("DMG Window Preview")
                .foregroundColor(.secondary)
                .position(x: 120, y: 20)
            
            // App Icon
            VStack {
                Image(systemName: "app")
                    .resizable()
                    .frame(width: 64, height: 64)
                Text("App")
            }
            .position(config.appPoint)
            
            // Applications
            VStack {
                Image(systemName: "folder")
                    .resizable()
                    .frame(width: 64, height: 64)
                Text("Applications")
            }
            .position(config.applicationPoint)
        }
        .aspectRatio(
            CGFloat(config.windowSize.width) / CGFloat(config.windowSize.height),
            contentMode: .fit
        )
        .padding()
    }
}
