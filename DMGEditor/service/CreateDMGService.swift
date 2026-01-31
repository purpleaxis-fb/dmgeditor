//
//  CreateDMGService.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

// Service/CreateDMGService.swift
import Foundation
import Cocoa

enum CreateDMGService {

    /// 清理 DMG 生成过程中的临时文件
    /// 临时文件格式: rw.{pid}.{dmgname}.dmg
    private static func cleanupTemporaryDMGFiles(in outputPath: String, log: @escaping (String) -> Void) {
        let fileManager = FileManager.default
        let outputDir = (outputPath as NSString).deletingLastPathComponent
        
        guard fileManager.fileExists(atPath: outputDir) else {
            return
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: outputDir)
            var cleanedCount = 0
            
            for file in files {
                // 查找临时文件 rw.*.dmg 或 rw.*.dmg.?
                if file.hasPrefix("rw.") && file.hasSuffix(".dmg") {
                    let filePath = "\(outputDir)/\(file)"
                    do {
                        try fileManager.removeItem(atPath: filePath)
                        cleanedCount += 1
                        log("🧹 Cleaned temp file: \(file)")
                    } catch {
                        log("⚠️ Failed to clean temp file \(file): \(error.localizedDescription)")
                    }
                }
            }
            
            if cleanedCount > 0 {
                log("✅ Cleaned \(cleanedCount) temporary file(s)")
            }
        } catch {
            log("⚠️ Could not read output directory for cleanup: \(error.localizedDescription)")
        }
    }

    /// 设置缓存目录中的 support 文件
    static func setupSupportFilesInCache() throws -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let supportDir = cacheDir.appendingPathComponent("DMGEditor/support")
        
        let templateApplescriptPath = supportDir.appendingPathComponent("template.applescript").path
        let eulaPath = supportDir.appendingPathComponent("eula-resources-template.xml").path
        
        // 检查是否需要重新复制文件（如果文件不存在或损坏）
        let needsSetup = !FileManager.default.fileExists(atPath: templateApplescriptPath) ||
                         !FileManager.default.fileExists(atPath: eulaPath)
        
        if !needsSetup {
            // 文件都存在，直接返回
            return supportDir
        }
        
        // 创建缓存目录
        if !FileManager.default.fileExists(atPath: supportDir.path) {
            try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        }
        
        // 从应用 bundle 的 Resources 中复制支持文件
        guard let bundlePath = Bundle.main.path(forResource: "create-dmg", ofType: "") else {
            throw NSError(domain: "CreateDMGService", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Could not find create-dmg in bundle"])
        }
        
        let resourcesDir = (bundlePath as NSString).deletingLastPathComponent
        
        // 复制 template.applescript
        let templateApplescriptSrc = "\(resourcesDir)/template.applescript1"
        
        // 首先尝试删除旧文件（如果存在且损坏）
        if FileManager.default.fileExists(atPath: templateApplescriptPath) {
            try FileManager.default.removeItem(atPath: templateApplescriptPath)
        }
        
        if FileManager.default.fileExists(atPath: templateApplescriptSrc) {
            try FileManager.default.copyItem(atPath: templateApplescriptSrc, toPath: templateApplescriptPath)
        } else {
            // 如果 .applescript 文件不存在，尝试查找 .scpt 文件
            let templateScptSrc = "\(resourcesDir)/template.scpt"
            if FileManager.default.fileExists(atPath: templateScptSrc) {
                // 使用 osacompile 将编译后的脚本转换回 .applescript 格式
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osacompile")
                process.arguments = ["-o", templateApplescriptPath, templateScptSrc]
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    if process.terminationStatus != 0 {
                        throw NSError(domain: "CreateDMGService", code: Int(process.terminationStatus),
                                     userInfo: [NSLocalizedDescriptionKey: "osacompile failed"])
                    }
                } catch {
                    throw NSError(domain: "CreateDMGService", code: -2,
                                 userInfo: [NSLocalizedDescriptionKey: "Failed to compile AppleScript: \(error)"])
                }
            } else {
                throw NSError(domain: "CreateDMGService", code: -3,
                             userInfo: [NSLocalizedDescriptionKey: "template.applescript or template.scpt not found"])
            }
        }
        
        // 复制 eula-resources-template.xml
        let eulaSrc = "\(resourcesDir)/eula-resources-template.xml"
        if FileManager.default.fileExists(atPath: eulaPath) {
            try FileManager.default.removeItem(atPath: eulaPath)
        }
        
        if FileManager.default.fileExists(atPath: eulaSrc) {
            try FileManager.default.copyItem(atPath: eulaSrc, toPath: eulaPath)
        }
        
        return supportDir
    }

    static func build(config: DMGConfig, log: @escaping (String) -> Void) throws -> URL? {
        guard let appPath = config.appPath else {
            log("❌ No app selected")
            throw NSError(domain: "CreateDMGService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No application selected. Please specify the application to be packaged."])
        }

        // 验证源文件夹是否存在
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: appPath.path, isDirectory: &isDir), isDir.boolValue else {
            let errorMsg = "App path does not exist or is not a directory: \(appPath.path)"
            log("❌ \(errorMsg)")
            throw NSError(domain: "CreateDMGService", code: 1002, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        log("📋 Build Configuration:")
        log("   App Path: \(appPath.path)")
        log("   App Path Exists: ✅")
        log("   DMG Name: \(config.dmgName)")
        log("   Volume Name: \(config.volumeName)")
        log("   Output Path: \(config.outputPath.path)")
        
        // 诊断信息：检查输出目录的可写性
        let outputDirPath = config.outputPath.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputDirPath) {
            log("   Output Dir Exists: ✅")
            log("   Output Dir Writable: \(fileManager.isWritableFile(atPath: outputDirPath) ? "✅" : "❌")")
        } else {
            log("   Output Dir Exists: ❌ (will be created)")
        }
        
        // 诊断信息：列出源文件夹内容
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: appPath.path)
            log("   Source folder contains \(contents.count) items")
        } catch {
            log("   ⚠️ Could not list source folder contents: \(error.localizedDescription)")
        }

        // 尝试多个位置获取 create-dmg 脚本
        var createDmgPath: String?
        
        // 1. 首先尝试从 Bundle 的 Resources 获取
        if let bundlePath = Bundle.main.path(forResource: "create-dmg", ofType: "") {
            if FileManager.default.fileExists(atPath: bundlePath) {
                createDmgPath = bundlePath
            }
        }
        
        // 2. 尝试从应用包 Contents/Resources 获取
        if createDmgPath == nil {
            if let appBundlePath = Bundle.main.bundlePath.components(separatedBy: ".app/").first?.appending(".app") {
                let resourcePath = "\(appBundlePath)/Contents/Resources/create-dmg"
                if FileManager.default.fileExists(atPath: resourcePath) {
                    createDmgPath = resourcePath
                }
            }
        }
        
        // 3. 尝试从系统 PATH 中获取
        if createDmgPath == nil {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = ["create-dmg"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    createDmgPath = path
                }
            } catch {
                log("⚠️ Could not check system PATH for create-dmg")
            }
        }
        
        guard let createDmgPath = createDmgPath else {
            let errorMsg = "create-dmg script not found. Please ensure it is installed and accessible in the system's PATH or included in the app bundle."
            log("❌ \(errorMsg)")
            throw NSError(domain: "CreateDMGService", code: 1003, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        log("✅ Found create-dmg at: \(createDmgPath)")

        let process = Process()
        // 使用 /usr/bin/env 来确保环境变量被正确传递
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        
        // 设置环境变量为 UTF-8，以支持中文路径和文件名
        var environment = ProcessInfo.processInfo.environment
        environment["LANG"] = "en_US.UTF-8"
        environment["LC_ALL"] = "en_US.UTF-8"
        process.environment = environment

        var args: [String] = []
        
        // 将 create-dmg 脚本本身作为 env 的第一个参数
        args.append(createDmgPath)
        
        // 设置 support 目录（从缓存中获取）
        do {
            let supportDirURL = try setupSupportFilesInCache()
            args.append(contentsOf: ["--support-dir", supportDirURL.path])
            log("✅ Support dir: \(supportDirURL.path)")
            
            // 验证 support 文件是否存在和有效
            let templatePath = supportDirURL.appendingPathComponent("template.applescript").path
            let eulaPath = supportDirURL.appendingPathComponent("eula-resources-template.xml").path
            
            let templateExists = FileManager.default.fileExists(atPath: templatePath)
            let eulaExists = FileManager.default.fileExists(atPath: eulaPath)
            
            log("   template.applescript exists: \(templateExists)")
            log("   eula-resources-template.xml exists: \(eulaExists)")
            
            // 验证文件大小
            if templateExists {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: templatePath),
                   let size = attrs[.size] as? NSNumber {
                    log("   template.applescript size: \(size.intValue) bytes")
                }
            }
            
            if !templateExists || !eulaExists {
                let errorMsg = "Required support files (template.applescript, eula-resources-template.xml) are missing in the cache."
                log("❌ \(errorMsg)")
                throw NSError(domain: "CreateDMGService", code: 1004, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        } catch {
            log("⚠️ Failed to setup support files: \(error.localizedDescription)")
            throw error
        }
        
        // 添加详细日志参数
        args.append("--hdiutil-verbose")
        
        // 基本配置
        args.append(contentsOf: ["--volname", config.volumeName])
        args.append(contentsOf: ["--window-size",
                                 "\(Int(config.windowSize.width))",
                                 "\(Int(config.windowSize.height))"])
        args.append(contentsOf: ["--icon-size", String(config.iconSize)])

        // 卷宗图标
        if let volumeIcon = config.volumeIconPath {
            args.append(contentsOf: ["--volicon", volumeIcon])
        }

        // 背景图片
        if let bg = config.processedBackgroundImageURL {
            args.append(contentsOf: ["--background", bg.path])
        }

        // 根据 items 添加文件位置和 icon
        for item in config.items {
            // 直接使用 iconCenter 来计算 create-dmg 的坐标
            let centerX = Int(item.iconCenter.x)
            let centerY = item.iconCenter.y
            let flippedY = Int(centerY)
            
            let sanitizedFileName = item.fileName
            
            switch item.type {
            case .app:
                // app 项目
                args.append(contentsOf: [
                    "--icon",
                    sanitizedFileName,
                    String(centerX),
                    String(flippedY)
                ])
            case .applications:
                // Applications 文件夹链接
                args.append(contentsOf: [
                    "--app-drop-link",
                    String(centerX),
                    String(flippedY)
                ])
            case .file:
                // 其他文件或文件夹
                args.append(contentsOf: [
                    "--add-file",
                    sanitizedFileName,
                    item.filePath,
                    String(centerX),
                    String(flippedY)
                ])
            }
            
            // 如果需要，隐藏文件扩展名
            if item.hideExtension {
                args.append(contentsOf: ["--hide-extension", sanitizedFileName])
            }
        }

        // 输出文件路径
        let baseOutputURL = config.outputPath.appendingPathComponent("\(config.dmgName).dmg")
        let uniqueOutputURL = generateUniqueURL(for: baseOutputURL)
        let dmgOutputPath = uniqueOutputURL.path
        
        // 确保输出目录存在并验证权限
        let outputDirPath2 = config.outputPath.path
        if !FileManager.default.fileExists(atPath: outputDirPath2) {
            do {
                try FileManager.default.createDirectory(atPath: outputDirPath2, withIntermediateDirectories: true, attributes: nil)
                log("✅ Created output directory: \(outputDirPath)")
            } catch {
                log("❌ Failed to create output directory: \(error.localizedDescription)")
                return nil
            }
        }
        
        // 验证输出目录是否可写
        if !FileManager.default.isWritableFile(atPath: outputDirPath2) {
            log("❌ Output directory is not writable: \(outputDirPath)")
            log("   Please check permissions or choose a different output location")
            return nil
        }
        
        // 诊断：检查磁盘空间
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: outputDirPath)
            if let freeSpace = attrs[FileAttributeKey.systemFreeSize] as? NSNumber {
                let freeGB = freeSpace.int64Value / (1024 * 1024 * 1024)
                log("   Available disk space: \(freeGB)GB")
            }
        } catch {
            log("   ⚠️ Could not check disk space: \(error.localizedDescription)")
        }
        
        log("   Output file: \(dmgOutputPath)")
        
        args.append(contentsOf: [
            dmgOutputPath,
            appPath.path
        ])

        process.arguments = args
        
        // 记录完整的命令参数
        log("📝 Command arguments:")
        log("/usr/bin/env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 " + args.joined(separator: " "))

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            
            // 读取所有输出
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            process.waitUntilExit()
            
            if let outputStr = String(data: outputData, encoding: .utf8), !outputStr.isEmpty {
                log(outputStr)
            }
            
            if let errorStr = String(data: errorData, encoding: .utf8), !errorStr.isEmpty {
                log("⚠️ STDERR:")
                log(errorStr)
            }
            
            log("⏹️ Process exited with code: \(process.terminationStatus)")
            
            // 清理临时文件（无论成功还是失败）
            cleanupTemporaryDMGFiles(in: dmgOutputPath, log: log)
            
            // 检查文件是否成功生成
            if FileManager.default.fileExists(atPath: dmgOutputPath) {
                log("✅ DMG 创建成功: \(dmgOutputPath)")
                return URL(fileURLWithPath: dmgOutputPath)
            } else {
                let errorMsg = "DMG file was not found after the build process completed (exit code: \(process.terminationStatus)). Check the log for errors from the create-dmg script."
                log("❌ \(errorMsg)")
                throw NSError(domain: "CreateDMGService", code: 1005, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
        } catch {
            log("❌ Failed to run create-dmg: \(error.localizedDescription)")
            throw error
        }
    }

    private static func generateUniqueURL(for url: URL) -> URL {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            // The original URL is already unique.
            return url
        }

        let directory = url.deletingLastPathComponent()
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        var counter = 2
        var newURL: URL

        repeat {
            let newFileName = "\(fileName) \(counter).\(fileExtension)"
            newURL = directory.appendingPathComponent(newFileName)
            counter += 1
        } while fileManager.fileExists(atPath: newURL.path)

        return newURL
    }
    
    
    private static func safeFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_()[]"))
        
        return name
            .unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
    }
}
