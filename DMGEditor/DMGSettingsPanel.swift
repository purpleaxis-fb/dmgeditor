//
//  DMGSettingsPanel.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

// UI/DMGSettingsPanel.swift
import SwiftUI
import AppKit

struct DMGSettingsPanel: View {
    @Binding var config: DMGConfig
    @Binding var isAutoSaveEnabled: Bool
    var onItemAdd: ((URL) -> Void)?

    var body: some View {
        Form {
            
            Section {
                VStack(spacing: 12) {
                    DMGFileDropView(title: "Drop .app here", fileType: .app) { url in
                        onItemAdd?(url)
                    }
                    
                    // 显示 App Icon 预览
                    if let appItem = config.items.first(where: { $0.type == .app }),
                       !appItem.icon.isEmpty {
                        HStack(spacing: 12) {
                            if let image = loadImage(from: appItem.icon) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 64, height: 64)
                                    .cornerRadius(8)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appItem.fileName)
                                    .font(.system(.body, design: .default))
                                    .fontWeight(.semibold)
                                Text(appItem.filePath)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            } header: {
                Text("App")
            }

            Section {
                Toggle("Enable Auto-Save", isOn: $isAutoSaveEnabled)
            } header: {
                Text("Archive")
            }
            
            Section {
                TextField("DMG Name", text: $config.dmgName)
                TextField("Volume Name", text: $config.volumeName)
            } header: {
                Text("DMG Info")
            }
            
            Section {
                VStack(spacing: 12) {
                    DMGFileDropView(title: "Drop Volume Icon (icns, png, jpg)", fileType: .image) { url in
                        config.setVolumeIcon(from: url)
                    }
                    
                    Button("Choose Icon...") {
                        selectVolumeIcon()
                    }
                    .frame(maxWidth: .infinity)

                    if let iconPath = config.volumeIconPath,
                       let image = loadImage(from: iconPath) {
                        HStack {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .cornerRadius(8)
                            VStack(alignment: .leading) {
                                Text("Custom Volume Icon")
                                Text(URL(fileURLWithPath: iconPath).lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        Text("Default volume icon is App Icon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Volume Icon")
            }
            
            Section {
                HStack {
                    Text("Output Path")
                    Spacer()
                    Text(config.outputPath.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: { selectOutputPath() }) {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.bordered)
                }
            } header: {
                Text("Output")
            }

            Section("Window") {
                HStack {
                    Text("Width")
                    Spacer()
                    TextField("", text: Binding(
                        get: { String(Int(config.windowSize.width)) },
                        set: { if let v = Int($0) { config.windowSize.width = CGFloat(v) } }
                    ))
                    .frame(width: 80)
                }

                HStack {
                    Text("Height")
                    Spacer()
                    TextField("", text: Binding(
                        get: { String(Int(config.windowSize.height)) },
                        set: { if let v = Int($0) { config.windowSize.height = CGFloat(v) } }
                    ))
                    .frame(width: 80)
                }

                HStack {
                    Text("Icon Size")
                    Spacer()
                    TextField("", text: Binding(
                        get: { String(config.iconSize) },
                        set: { if let v = Int($0) { config.iconSize = v } }
                    ))
                    .frame(width: 80)
                }
                
                HStack {
                    Text("Clip to Bounds")
                    Spacer()
                    Toggle("", isOn: $config.clipItemsToBounds)
                        .labelsHidden()
                }
            }

            Section {
                VStack(spacing: 12) {
                    DMGFileDropView(title: "Drop Background Image", fileType: .image) { url in
                        config.setBackgroundImage(from: url)
                    }
                    
                    // 显示背景图片缩略图
                    if let bgURL = config.processedBackgroundImageURL,
                       let image = NSImage(contentsOf: bgURL) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(6)
                    }
                }
            } header: {
                Text("Background")
            }
            
            Section {
                VStack(spacing: 12) {
                    DMGFileDropView(title: "Add File or Folder Item", fileType: .anyFile) { url in
                        onItemAdd?(url)
                    }
                    
                    Text("Drop or click to add a file or folder item to the DMG")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Add Items")
            }
        }
        .formStyle(.grouped)
    }
    
    /// 从路径或系统图标名加载图像
    private func loadImage(from iconString: String) -> NSImage? {
        // 如果是文件路径
        if iconString.hasPrefix("/") {
            return NSImage(contentsOfFile: iconString)
        }
        // 否则尝试加载系统图标
        return NSImage(named: iconString)
    }
    
    /// 选择输出路径
    private func selectOutputPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = config.outputPath
        panel.prompt = "Select Output Folder"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                config.outputPath = url
            }
        }
    }
    
    /// 选择卷标图标
    private func selectVolumeIcon() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["icns", "png", "jpg", "jpeg"]
        panel.prompt = "Select Icon"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                config.setVolumeIcon(from: url)
            }
        }
    }
}
