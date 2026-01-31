//
//  DMGEditorViewModel.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//

import SwiftUI
import Combine
import AppKit

final class DMGEditorViewModel: ObservableObject {

    @Published var config = DMGConfig()
    @Published var selectedItemId: String? = nil
    @Published var isAutoSaveEnabled: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let configService = ConfigService.shared

    init() {
        // 自动读档
        loadAutoSavedConfig()
        
        // 自动存档
        $config
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.autoSaveConfig()
            }
            .store(in: &cancellables)
    }

    func moveItem(id: String, to point: CGPoint, iconCenter: CGPoint) {
        config.updatePosition(itemId: id, position: point)
        config.updateIconCenter(itemId: id, iconCenter: iconCenter)
    }
    
    func moveItem(id: String, to point: CGPoint) {
        config.updatePosition(itemId: id, position: point)
    }

    func removeItem(id: String) throws {
        try config.removeItem(itemId: id)
        if selectedItemId == id {
            selectedItemId = nil
        }
    }
    
    func addFileItem(fileURL: URL, showAlert: @escaping (String, String) -> Void) {
        let fileName = fileURL.lastPathComponent
        let illegalChars = illegalCharacters(in: fileName)
        
        guard illegalChars.isEmpty else {
            let illegalCharsString = illegalChars.map { String($0) }.joined(separator: ", ")
            showAlert(
                "Invalid File Name",
                "The file name \"\(fileName)\" contains illegal characters: \(illegalCharsString).\n\nPlease rename the file and try again.\n\nForbidden characters are: / \\ : ? * \" < > |"
            )
            return
        }
        
        do {
            // 判断是 App 还是普通文件
            if fileURL.pathExtension.lowercased() == "app" {
                // 如果是 App，则加载整个 App Bundle
                try config.loadAppBundle(appURL: fileURL)
            } else {
                // 如果是普通文件，则添加为文件 Item
                try config.addFileItem(from: fileURL)
            }
        } catch {
            // 捕获错误并显示弹窗
            showAlert("Error Adding Item", error.localizedDescription)
        }
    }
    
    private func illegalCharacters(in name: String) -> [Character] {
        let illegalSet = CharacterSet(charactersIn: "/\\:?*\"<>|")
        return name.filter {
            String($0).rangeOfCharacter(from: illegalSet) != nil
        }
    }
    
    func getSelectedItem() -> DMGItemModel? {
        guard let selectedItemId = selectedItemId else { return nil }
        return config.items.first(where: { $0.id == selectedItemId })
    }
    
    // MARK: - 存档与读档
    
    /// 手动保存项目
    func saveProject(showAlert: @escaping (String, String) -> Void) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["json"]
        panel.nameFieldStringValue = "\(config.dmgName).json"
        
        panel.begin { [weak self] result in
            guard let self = self, result == .OK, let url = panel.url else { return }
            do {
                try self.configService.saveConfig(self.config, to: url)
            } catch {
                showAlert("Save Error", "Failed to save project: \(error.localizedDescription)")
            }
        }
    }
    
    /// 手动加载项目
    func loadProject(showAlert: @escaping (String, String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["json"]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] result in
            guard let self = self, result == .OK, let url = panel.url else { return }
            do {
                self.config = try self.configService.loadConfig(from: url)
            } catch {
                showAlert("Load Error", "Failed to load project: \(error.localizedDescription)")
            }
        }
    }
    
    /// 自动存档
    private func autoSaveConfig() {
        guard isAutoSaveEnabled, let url = configService.getAutoSaveURL() else { return }
        do {
            try configService.saveConfig(config, to: url)
            print("Auto-saved config to \(url.path)")
        } catch {
            print("Failed to auto-save config: \(error)")
        }
    }
    
    /// 加载自动存档的配置
    private func loadAutoSavedConfig() {
        guard let url = configService.getAutoSaveURL(),
              FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            self.config = try configService.loadConfig(from: url)
            print("Loaded auto-saved config from \(url.path)")
        } catch {
            print("Failed to load auto-saved config: \(error)")
        }
    }
}
