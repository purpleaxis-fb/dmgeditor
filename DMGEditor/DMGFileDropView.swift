//
//  FileDropView.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

// UI/FileDropView.swift
import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

struct DMGFileDropView: View {
    let title: String
    let fileType: FileType  // 文件类型
    let onDrop: (URL) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Rectangle()
            .fill(isHovering ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .frame(height: 60)
            .overlay(
                Text(title)
                    .foregroundColor(.secondary)
            )
            .cornerRadius(6)
            .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
                providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                    if let data = data as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            onDrop(url)
                        }
                    }
                }
                return true
            }
            .onTapGesture {
                openFilePanel()
            }
    }
    
    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = (fileType == .app)
        panel.canChooseFiles = true
        
        switch fileType {
        case .app:
            panel.title = "Select .app Bundle"
            panel.prompt = "Select"
            panel.allowedContentTypes = []  // 允许选择任何文件和目录
        case .image:
            panel.title = "Select Background Image"
            panel.prompt = "Select"
            panel.allowedContentTypes = [.image]
        case .anyFile:
            panel.title = "Select File or Folder"
            panel.prompt = "Select"
            panel.canChooseDirectories = true
            panel.allowedContentTypes = []  // 允许选择任何文件和目录
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // 对于 .app 文件，检查是否是有效的 .app 包
                if fileType == .app {
                    let isAppBundle = url.pathExtension.lowercased() == "app" ||
                                     FileManager.default.fileExists(atPath: url.appendingPathComponent("Contents").path)
                    if isAppBundle {
                        onDrop(url)
                    } else {
                        showAlert(title: "Invalid Selection", message: "Please select a valid .app bundle")
                    }
                } else {
                    onDrop(url)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum FileType {
    case app
    case image
    
    case anyFile
}
