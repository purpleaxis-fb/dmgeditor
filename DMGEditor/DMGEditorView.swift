//
//  DMGEditorView.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

struct DMGEditorView: View {
    
    @StateObject private var viewModel = DMGEditorViewModel()
    @EnvironmentObject private var alertManager: AlertManager
    
    @State private var log: String = ""
    @State private var showEditPanel = false
    @State private var isBuilding = false
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            // 左侧：切换面板
            VStack(spacing: 0) {
                Picker("", selection: $showEditPanel) {
                    Text("Settings").tag(false)
                    Text("Edit Item").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                if showEditPanel {
                    DMGItemEditPanel(
                        config: $viewModel.config,
                        selectedItemId: viewModel.selectedItemId,
                        onRemoveItem: { id in
                            do {
                                try viewModel.removeItem(id: id)
                            } catch {
                                alertManager.showAlert(title: "Error", message: error.localizedDescription)
                            }
                        }
                    )
                } else {
                    DMGSettingsPanel(
                        config: $viewModel.config,
                        isAutoSaveEnabled: $viewModel.isAutoSaveEnabled,
                        onItemAdd: { url in
                            viewModel.addFileItem(fileURL: url) { title, message in
                                alertManager.showAlert(title: title, message: message)
                            }
                        }
                    )
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 300)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        viewModel.saveProject(showAlert: { title, msg in
                            alertManager.showAlert(title: title, message: msg)
                        })
                    }) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    
                    Button(action: {
                        viewModel.loadProject(showAlert: { title, msg in
                            alertManager.showAlert(title: title, message: msg)
                        })
                    }) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Load")
                    }
                }
            }
            
            Divider()
            
            // 右侧：可视化画板
            VStack(spacing: 5) {
                GeometryReader { geometry in
                    let availableSize = geometry.size
                    let configSize = viewModel.config.windowSize
                    
                    let scaleX = availableSize.width / configSize.width
                    let scaleY = availableSize.height / configSize.height
                    let scale = min(scaleX, scaleY, 1.0)
                    
                    let canvasSize = CGSize(width: configSize.width * scale, height: (configSize.height) * scale)
                    
                    DMGCanvasView(
                        config: viewModel.config,
                        backgroundImageURL: viewModel.config.processedBackgroundImageURL,
                        clipItemsToBounds: viewModel.config.clipItemsToBounds,
                        selectedItemId: viewModel.selectedItemId,
                        scale: scale,
                        onItemMoved: { id, point, iconCenter in
                            viewModel.moveItem(id: id, to: point, iconCenter: iconCenter)
                        }, onItemTapped: { id in
                            viewModel.selectedItemId = id
                            showEditPanel = true
                        }, onItemAdd: { url in
                            viewModel.addFileItem(fileURL: url) { title, message in
                                alertManager.showAlert(title: title, message: message)
                            }
                        }
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                HStack(spacing: 12) {
                    Button("Build DMG") {
                        isBuilding = true
                        log.append("正在生成 DMG...\n")
                        
                        DispatchQueue.global().async {
                            do {
                                if let dmgURL = try CreateDMGService.build(config: viewModel.config, log: { output in
                                    DispatchQueue.main.async {
                                        log.append(output)
                                    }
                                }) {
                                    DispatchQueue.main.async {
                                        log.append("\n✅ DMG 生成完成，准备保存...\n")
                                        isBuilding = false
                                        showSavePanel(for: dmgURL)
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        isBuilding = false
                                        alertManager.showAlert(title: "Build Failed", message: "DMG file was not created. Check the log for details.")
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    isBuilding = false
                                    alertManager.showAlert(title: "Build Error", message: error.localizedDescription)
                                }
                            }
                        }
                    }
                    .disabled(isBuilding)
                    
                    Spacer()
                }
                .padding()
                
                HStack(spacing: 8) {
                    Text("📋 Build Log")
                        .font(.system(size: 11, weight: .semibold))
                    
                    Spacer()
                    
                    Button(action: {
                        log = ""
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 14))
                    }
                    .help("Clear log")
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                ScrollView {
                    Text(log)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                .frame(height: 120)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .alert(item: $alertManager.alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
    }
    
    /// 显示另存为对话框
    private func showSavePanel(for dmgURL: URL) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = dmgURL.lastPathComponent
        savePanel.allowedContentTypes = [.init(filenameExtension: "dmg")!]
        savePanel.directoryURL = viewModel.config.outputPath
        
        savePanel.begin { result in
            if result == .OK, let selectedURL = savePanel.url {
                // 移动文件到选择的位置
                do {
                    if FileManager.default.fileExists(atPath: selectedURL.path) {
                        try FileManager.default.removeItem(at: selectedURL)
                    }
                    try FileManager.default.moveItem(at: dmgURL, to: selectedURL)
                    
                    DispatchQueue.main.async {
                        self.log.append("✅ DMG 已保存到: \(selectedURL.path)\n")
                        
                        // 更新默认输出路径
                        self.viewModel.config.outputPath = selectedURL.deletingLastPathComponent()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.log.append("❌ 保存失败: \(error.localizedDescription)\n")
                        self.alertManager.showAlert(title: "Save Error", message: "Failed to move DMG to the selected location: \(error.localizedDescription)")
                    }
                }
            } else {
                // 用户取消了保存
                do {
//                    try FileManager.default.removeItem(at: dmgURL)
                    DispatchQueue.main.async {
                        self.log.append("⚠️ 保存已取消\n")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.log.append("⚠️ 无法删除临时文件: \(error.localizedDescription)\n")
                    }
                }
            }
        }
    }
}
