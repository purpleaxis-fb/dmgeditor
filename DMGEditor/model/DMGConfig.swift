//
//  DMGConfig.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

// Model/DMGConfig.swift
import Cocoa

struct DMGConfig: Codable {
    
    /// Titlebar高度，用于坐标转换
    /// 画板显示时减去这个高度，计算实际位置时需要加回来
    static let titlebarHeight: CGFloat = 32

    var appPath: URL?

    var dmgName: String = "MyApp"
    var volumeName: String = "MyApp Installer"
    var volumeIconPath: String?
    
    /// DMG 输出路径，默认为 Desktop
    /// 注意：应用运行在沙箱中，只有真实的用户 Desktop 是可写的
    var outputPath: URL = {
        // 优先使用真实的用户 Desktop
        let desktop = NSHomeDirectory() + "/Desktop"
        if FileManager.default.isWritableFile(atPath: desktop) {
            return URL(fileURLWithPath: desktop)
        }
        // 备选方案：使用 Documents 文件夹
        let documents = NSHomeDirectory() + "/Documents"
        if FileManager.default.isWritableFile(atPath: documents) {
            return URL(fileURLWithPath: documents)
        }
        // 最后的备选：使用 Downloads 文件夹
        let downloads = NSHomeDirectory() + "/Downloads"
        return URL(fileURLWithPath: downloads)
    }()

    var windowSize = CGSize(width: 600, height: 400) {
        didSet {
            // 当窗口尺寸变化时，重新生成背景图
            regenerateProcessedBackgroundImage()
        }
    }
    var iconSize: Int = 96 {
        didSet {
            // 当 iconSize 改变时，更新所有 items 的大小
            updateAllItemsSizes()
        }
    }

    /// 用户选择的原始背景图片
    private(set) var originalBackgroundImageURL: URL?
    /// 经过处理后用于显示和打包的背景图片
    private(set) var processedBackgroundImageURL: URL?
    
    /// 是否限制 item 拖动范围在画板内
    var clipItemsToBounds: Bool = true

    private(set) var items: [DMGItemModel]

    init() {
        self.items = [
            DMGItemModel(
                type: .app,
                position: CGPoint(x: 150, y: 200),
                filePath: "",
                fileName: "MyApp.app",
                icon: "NSFolderSmart"
            ),
            DMGItemModel(
                type: .applications,
                position: CGPoint(x: 450, y: 200),
                filePath: "/Applications",
                fileName: "Applications",
                icon: "NSFolderBurnable"
            )
        ]
        // 初始化所有 items 的大小为 iconSize
        updateAllItemsSizes()
    }
    
    /// 设置背景图片，并触发处理流程
    mutating func setBackgroundImage(from url: URL?) {
        originalBackgroundImageURL = url
        regenerateProcessedBackgroundImage()
    }

    /// 重新生成处理后的背景图片
    private mutating func regenerateProcessedBackgroundImage() {
        guard let originalURL = originalBackgroundImageURL,
              let originalImage = NSImage(contentsOf: originalURL) else {
            processedBackgroundImageURL = nil
            return
        }

        if let processedImage = processBackgroundImage(originalImage, to: windowSize) {
            if let cachedURL = saveProcessedImageToCache(processedImage) {
                processedBackgroundImageURL = cachedURL
            } else {
                // 如果缓存失败，则清空
                processedBackgroundImageURL = nil
            }
        } else {
            // 如果处理失败，则清空
            processedBackgroundImageURL = nil
        }
    }

    /// 将图片处理成适应目标尺寸的背景图
    private func processBackgroundImage(_ image: NSImage, to targetSize: CGSize) -> NSImage? {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()

        // 1. 填充白色背景
        NSColor.white.setFill()
        NSRect(origin: .zero, size: targetSize).fill()

        // 2. 计算图片等比缩放后的尺寸
        let imageSize = image.size
        var newDrawSize = imageSize

        if imageSize.width > targetSize.width || imageSize.height > targetSize.height {
            // 图片比窗口大，需要缩放
            let widthRatio = targetSize.width / imageSize.width
            let heightRatio = targetSize.height / imageSize.height
            let scaleFactor = min(widthRatio, heightRatio) // 保证能完全放入
            newDrawSize = CGSize(width: imageSize.width * scaleFactor, height: imageSize.height * scaleFactor)
        }

        // 3. 计算居中绘制的原点
        let drawOrigin = CGPoint(
            x: (targetSize.width - newDrawSize.width) / 2,
            y: (targetSize.height - newDrawSize.height) / 2
        )

        // 4. 将原图绘制到新的画布上
        let drawRect = NSRect(origin: drawOrigin, size: newDrawSize)
        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

        newImage.unlockFocus()
        return newImage
    }

    /// 将处理后的图片保存到缓存目录
    private func saveProcessedImageToCache(_ image: NSImage) -> URL? {
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("DMGEditor/ProcessedBackground") else {
            return nil
        }

        do {
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create cache directory for processed background: \(error)")
            return nil
        }

        let fileName = "\(UUID().uuidString).png"
        let fileURL = cacheDir.appendingPathComponent(fileName)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save processed image to cache: \(error)")
            return nil
        }
    }
    
    var appPoint : CGPoint{
        return self.items.first(where: {$0.type == .app})?.position ?? .zero
    }
    
    var applicationPoint : CGPoint{
        return self.items.first(where: {$0.type == .applications})?.position ?? .zero
    }
    // MARK: - Codable Implementation

    enum CodingKeys: String, CodingKey {
        case appPath, dmgName, volumeName, volumeIconPath, windowSize, iconSize
        case originalBackgroundImageURL = "backgroundImage" // 兼容旧 key
        case clipItemsToBounds, items, outputPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appPath = try container.decodeIfPresent(URL.self, forKey: .appPath)
        dmgName = try container.decode(String.self, forKey: .dmgName)
        volumeName = try container.decode(String.self, forKey: .volumeName)
        volumeIconPath = try container.decodeIfPresent(String.self, forKey: .volumeIconPath)
        windowSize = try container.decode(CGSize.self, forKey: .windowSize)
        iconSize = try container.decode(Int.self, forKey: .iconSize)
        originalBackgroundImageURL = try container.decodeIfPresent(URL.self, forKey: .originalBackgroundImageURL)
        clipItemsToBounds = try container.decode(Bool.self, forKey: .clipItemsToBounds)
        items = try container.decode([DMGItemModel].self, forKey: .items)
        outputPath = try container.decode(URL.self, forKey: .outputPath)
        
        // 读档后，立即重新生成背景图
        regenerateProcessedBackgroundImage()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(appPath, forKey: .appPath)
        try container.encode(dmgName, forKey: .dmgName)
        try container.encode(volumeName, forKey: .volumeName)
        try container.encodeIfPresent(volumeIconPath, forKey: .volumeIconPath)
        try container.encode(windowSize, forKey: .windowSize)
        try container.encode(iconSize, forKey: .iconSize)
        try container.encodeIfPresent(originalBackgroundImageURL, forKey: .originalBackgroundImageURL)
        try container.encode(clipItemsToBounds, forKey: .clipItemsToBounds)
        try container.encode(items, forKey: .items)
        try container.encode(outputPath, forKey: .outputPath)
    }
}

// MARK: - Codable Conformance for CoreGraphics types
extension CGPoint: Codable {
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

extension CGSize: Codable {
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}


extension DMGConfig {

    mutating func addItem(_ item: DMGItemModel) throws {
        if item.type.isUnique,
           items.contains(where: { $0.type == item.type }) {
            throw NSError(domain: "DMGConfig",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "\(item.type) already exists"])
        }
        
        // 排重：检查是否已存在相同路径的文件
        let path = item.filePath
        if !path.isEmpty, items.contains(where: { $0.filePath == path }) {
            throw NSError(domain: "DMGConfig",
                          code: 3, // Use a new error code for duplicate item
                          userInfo: [NSLocalizedDescriptionKey: "An item with the name \"\(URL(fileURLWithPath: path).lastPathComponent)\" already exists."])
        }

        // 确保 iconCenter 被正确初始化
        var mutableItem = item
        if mutableItem.iconCenter == .zero {
            mutableItem.iconCenter = calculateIconCenter(for: mutableItem)
        }
        items.append(mutableItem)
    }

    mutating func removeItem(itemId: String) throws {
        guard let item = items.first(where: { $0.id == itemId }) else {
            return
        }

        if item.type.isRequired {
            throw NSError(domain: "DMGConfig",
                          code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "\(item.type) is required"])
        }

        items.removeAll { $0.id == itemId }
    }

    mutating func updatePosition(itemId: String, position: CGPoint) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].position = position
        items[index].iconCenter = calculateIconCenter(for: items[index])
    }
    
    mutating func updateIconCenter(itemId: String, iconCenter: CGPoint) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].iconCenter = iconCenter
    }
    
    /// 根据 position 计算 iconCenter
    private func calculateIconCenter(for item: DMGItemModel) -> CGPoint {
        let selectionPadding: CGFloat = 6.0
        let textHeight: CGFloat = 18
        let spacing: CGFloat = 4
        
        let actualIconSize = CGSize(
            width: item.size.width - 2 * selectionPadding,
            height: item.size.height - 2 * selectionPadding
        )
        
        let iconOffsetY = textHeight + spacing + actualIconSize.height / 2
        let iconOffsetX = actualIconSize.width / 2
        
        return CGPoint(
            x: item.position.x + iconOffsetX,
            y: item.position.y + iconOffsetY
        )
    }
    
    mutating func updateItemHideExtension(itemId: String, hide: Bool) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].hideExtension = hide
    }

    mutating func updateItemSize(itemId: String, size: CGSize) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[index].size = size
    }
    
    /// 根据 iconSize 更新所有 items 的大小
    private mutating func updateAllItemsSizes() {
        let size = CGFloat(iconSize)
        let iconOffsetY: CGFloat = 26  // textHeight(18) + spacing(8)
        for i in 0..<items.count {
            let oldPosition = items[i].position
            items[i].size = CGSize(width: size, height: size)
            items[i].iconCenter = calculateIconCenter(for: items[i])
        }
    }
    
    /// 根据文件类型智能获取 icon
    mutating func getIconForPath(_ filePath: String) -> String {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: filePath)
        
        // 检查是否是 .app 包
        if url.pathExtension.lowercased() == "app" {
            // 对于 app，尝试提取 icon
            let appIcon = extractAppIcon(from: url)
            if !appIcon.isEmpty {
                return appIcon
            }
            return "NSFolderSmart"
        }
        
        // 检查是否是文件夹
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: filePath, isDirectory: &isDir), isDir.boolValue {
            return "NSFolderBurnable"
        }
        
        // 普通文件：获取系统文件类型图标
        let workspace = NSWorkspace.shared
        let image = workspace.icon(forFile: filePath)
        // 保存图标到临时位置，返回路径
        if let iconPath = saveSystemIcon(image, forFile: filePath) {
            return iconPath
        }
        
        // 默认文件图标
        return "doc.fill"
    }
    
    /// 保存系统获取的图标到临时目录
    private func saveSystemIcon(_ image: NSImage, forFile filePath: String) -> String? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dmgEditorCacheDir = cacheDir.appendingPathComponent("DMGEditor")
        
        try? FileManager.default.createDirectory(at: dmgEditorCacheDir, withIntermediateDirectories: true, attributes: nil)
        
        // 使用文件名的hash作为缓存文件名
        let fileNameHash = filePath.hashValue.magnitude.description
        let iconPath = dmgEditorCacheDir.appendingPathComponent("icon_\(fileNameHash).tiff")
        
        if let tiffData = image.tiffRepresentation {
            try? tiffData.write(to: iconPath)
            return iconPath.path
        }
        
        return nil
    }
    
    /// 根据 .app 文件路径更新 app 配置和 item
    mutating func loadAppBundle(appURL: URL) throws {
        appPath = appURL
        
        // 更新 DMG 名称
        let appName = appURL.deletingPathExtension().lastPathComponent
        dmgName = appName
        volumeName = "\(appName) Installer"
        
        // 从 .app bundle 中提取 AppIcon.icns
        let iconPath = extractAppIcon(from: appURL)
        volumeIconPath = iconPath
        
        // 更新或创建 app item
        if let index = items.firstIndex(where: { $0.type == .app }) {
            // 如果路径发生变化，检查是否与其他项冲突
            if items[index].filePath != appURL.path && items.contains(where: { $0.filePath == appURL.path && $0.type != .app }) {
                throw NSError(domain: "DMGConfig",
                              code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "An item with path \"\(appURL.lastPathComponent)\" already exists."])
            }
            items[index].filePath = appURL.path
            items[index].fileName = appURL.lastPathComponent
            items[index].icon = iconPath
            items[index].iconCenter = calculateIconCenter(for: items[index])
        } else {
            let appItem = DMGItemModel(
                type: .app,
                position: CGPoint(x: 100, y: 200), // 默认位置
                filePath: appURL.path,
                fileName: appURL.lastPathComponent,
                icon: iconPath
            )
            try addItem(appItem)
        }
    }
    
    /// 设置卷标图标，如果不是 .icns 格式则自动转换
    mutating func setVolumeIcon(from url: URL) {
        if url.pathExtension.lowercased() == "icns" {
            self.volumeIconPath = url.path
            return
        }
        
        // 如果是其他图片格式，则转换为 .icns
        if let image = NSImage(contentsOf: url) {
            let fileName = url.deletingPathExtension().lastPathComponent
            if let icnsPath = saveImageAsIcns(image: image, name: fileName) {
                self.volumeIconPath = icnsPath
            }
        }
    }
    
    /// 添加一个普通文件 Item，并自动提取其系统图标
    mutating func addFileItem(from url: URL) throws {
        let fileName = url.lastPathComponent
        
        // 获取文件的真实系统图标
        let iconImage = NSWorkspace.shared.icon(forFile: url.path)
        
        // 将图标保存到缓存并获取其路径
        let cacheName = url.deletingPathExtension().lastPathComponent
        let iconPath = saveImageAsIcns(image: iconImage, name: cacheName)

        let item = DMGItemModel(
            type: .file,
            position: CGPoint(x: 200, y: 200), // 默认位置
            filePath: url.path,
            fileName: fileName,
            icon: iconPath ?? "doc.fill" // 使用真实图标，如果失败则回退到通用图标
        )
        
        try addItem(item)
    }
        
    
    /// 从 .app bundle 中提取 AppIcon.icns 路径
    private func extractAppIcon(from appURL: URL) -> String {
        // .app 的路径结构: MyApp.app/Contents/Resources/AppIcon.icns
        let resourcePath = appURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
        
        let icnsPath = resourcePath.appendingPathComponent("AppIcon.icns")
        
        // 如果找到 AppIcon.icns，返回其路径
        if FileManager.default.fileExists(atPath: icnsPath.path) {
            return icnsPath.path
        }
        
        // 否则，尝试查找其他 .icns 文件
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: resourcePath,
                includingPropertiesForKeys: nil
            )
            if let icnsFile = contents.first(where: { $0.pathExtension.lowercased() == "icns" }) {
                return icnsFile.path
            }
        } catch {
            print("Failed to read Resources directory: \(error)")
        }
        
        // 尝试从 Assets.car 中提取 AppIcon
        print("Attempting to extract icon from Assets.car for: \(appURL.lastPathComponent)")
        if let extractedIconPath = extractIconFromAssetsCar(appURL: appURL) {
            print("Successfully extracted icon from Assets.car: \(extractedIconPath)")
            return extractedIconPath
        }
        
        // 最后使用 NSWorkspace 获取应用图标并生成 icns
        print("Attempting to extract icon via NSWorkspace for: \(appURL.lastPathComponent)")
        if let workspaceIconPath = extractIconViaWorkspace(appURL: appURL) {
            print("Successfully extracted icon via NSWorkspace: \(workspaceIconPath)")
            return workspaceIconPath
        }
        
        // 如果没有找到任何图标，返回默认图标名
        print("No icon found, using default icon for: \(appURL.lastPathComponent)")
        return "app.fill"
    }
    
    /// 从 Assets.car 中提取 AppIcon
    private func extractIconFromAssetsCar(appURL: URL) -> String? {
        let assetsPath = appURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Assets.car")
        
        guard FileManager.default.fileExists(atPath: assetsPath.path) else {
            print("Assets.car not found at: \(assetsPath.path)")
            return nil
        }
        
        // 创建临时缓存目录用于解包 Assets.car
        let tempCacheDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("DMGEditor_AssetCache_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(
                at: tempCacheDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("Created temporary cache directory: \(tempCacheDir.path)")
        } catch {
            print("Failed to create temporary cache directory: \(error)")
            return nil
        }
        
        defer {
            // 清理临时缓存目录
            try? FileManager.default.removeItem(at: tempCacheDir)
            print("Cleaned up temporary cache directory: \(tempCacheDir.path)")
        }
        
        // 使用 xcrun assetutil 解包 Assets.car 到临时目录
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["assetutil", "-I", assetsPath.path, "-o", tempCacheDir.path]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("assetutil failed with status \(process.terminationStatus): \(errorMessage)")
                return nil
            }
            
            print("Successfully extracted Assets.car to: \(tempCacheDir.path)")
            
            // 在临时目录中查找 AppIcon 相关的图片
            if let iconImage = extractAppIconFromCacheDir(tempCacheDir, appName: appURL.deletingPathExtension().lastPathComponent) {
                print("Found AppIcon image in Assets.car cache")
                return saveIconAsIcns(image: iconImage, appURL: appURL)
            }
        } catch {
            print("Failed to extract icon from Assets.car: \(error)")
        }
        
        return nil
    }
    
    /// 从缓存目录中查找并提取 AppIcon 图片
    private func extractAppIconFromCacheDir(_ cacheDir: URL, appName: String) -> NSImage? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDir,
                includingPropertiesForKeys: nil
            )
            
            // 查找包含 "AppIcon" 的图片文件
            let iconSearchPatterns = [
                "AppIcon", "app-icon", "AppIcon-1024"
            ]
            
            for item in contents {
                let fileName = item.lastPathComponent.lowercased()
                
                // 检查文件是否包含 icon 相关关键字且是图片格式
                let isImageFile = [".png", ".jpg", ".jpeg"].contains { fileName.hasSuffix($0) }
                let isIconFile = iconSearchPatterns.contains { fileName.contains($0.lowercased()) }
                
                if isImageFile && isIconFile {
                    if let image = NSImage(contentsOfFile: item.path) {
                        print("Found icon image: \(item.lastPathComponent)")
                        return image
                    }
                }
            }
            
            // 如果没有找到 AppIcon，尝试递归搜索子目录
            for item in contents {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir),
                   isDir.boolValue {
                    if let image = extractAppIconFromCacheDir(item, appName: appName) {
                        return image
                    }
                }
            }
        } catch {
            print("Failed to read cache directory: \(error)")
        }
        
        return nil
    }
    
    /// 通过 NSWorkspace 获取应用图标并生成 icns
    private func extractIconViaWorkspace(appURL: URL) -> String? {
        guard let icon = NSWorkspace.shared.icon(forFiles: [appURL.path]) else {
            return nil
        }
        
        return saveIconAsIcns(image: icon, appURL: appURL)
    }
    
    /// 将 NSImage 保存为 AppIcon.icns 文件
    private func saveIconAsIcns(image: NSImage, appURL: URL) -> String? {
        // 检查 appURL 是否为有效的 .app 包
        guard appURL.pathExtension.lowercased() == "app" else {
            print("Error: appURL is not a valid .app bundle: \(appURL.path)")
            return nil
        }
        
        let resourcePath = appURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
        
        // 首先尝试在原始应用目录中保存
        if isPathWritable(resourcePath) {
            if let icnsPath = tryCreateIconsetAndConvert(image: image, outputDir: resourcePath) {
                return icnsPath
            }
            if let sipsPath = tryConvertImageViaSips(image: image, outputDir: resourcePath) {
                return sipsPath
            }
            if let pngPath = trySaveImageAsPNG(image: image, outputDir: resourcePath) {
                return pngPath
            }
        } else {
            print("Original app directory is not writable: \(resourcePath.path)")
            print("Using cache directory instead")
        }
        
        // 如果原始目录不可写，使用用户缓存目录
        let appName = appURL.deletingPathExtension().lastPathComponent
        return saveImageAsIcns(image: image, name: appName)
    }
    
    /// 将 NSImage 保存为 .icns 文件到缓存目录
    private func saveImageAsIcns(image: NSImage, name: String) -> String? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("DMGEditor")
        
        guard let cacheDir = cacheDir else {
            print("Failed to get cache directory")
            return nil
        }
        
        // 创建缓存目录
        do {
            try FileManager.default.createDirectory(
                at: cacheDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Failed to create cache directory: \(error)")
            return nil
        }
        
        let cachedOutputDir = cacheDir.appendingPathComponent(name)
        
        do {
            try FileManager.default.createDirectory(
                at: cachedOutputDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("Failed to create cached output directory: \(error)")
            return nil
        }
        
        // 尝试在缓存目录中保存
        if let icnsPath = tryCreateIconsetAndConvert(image: image, outputDir: cachedOutputDir) {
            return icnsPath
        }
        if let sipsPath = tryConvertImageViaSips(image: image, outputDir: cachedOutputDir) {
            return sipsPath
        }
        if let pngPath = trySaveImageAsPNG(image: image, outputDir: cachedOutputDir) {
            return pngPath
        }
        
        print("Failed to save icon in any format")
        return nil
    }
    
    /// 检查路径是否可写
    private func isPathWritable(_ path: URL) -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path.path) {
            return fileManager.isWritableFile(atPath: path.path)
        }
        
        // 检查父目录是否可写
        let parentPath = path.deletingLastPathComponent()
        if fileManager.fileExists(atPath: parentPath.path) {
            return fileManager.isWritableFile(atPath: parentPath.path)
        }
        
        return false
    }
    
    /// 尝试使用 iconutil 创建 icns
    private func tryCreateIconsetAndConvert(image: NSImage, outputDir: URL) -> String? {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("DMGEditor_IconSet_\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let iconsetPath = tempDir.appendingPathComponent("AppIcon.iconset")
        let outputIcnsPath = outputDir.appendingPathComponent("AppIcon.icns")
        
        do {
            try FileManager.default.createDirectory(at: iconsetPath, withIntermediateDirectories: true)
            
            // 创建不同尺寸的图标
            let sizes: [(Int, String)] = [
                (16, "icon_16x16"),
                (32, "icon_16x16@2x"),
                (32, "icon_32x32"),
                (64, "icon_32x32@2x"),
                (128, "icon_128x128"),
                (256, "icon_128x128@2x"),
                (256, "icon_256x256"),
                (512, "icon_256x256@2x"),
                (512, "icon_512x512"),
                (1024, "icon_512x512@2x")
            ]
            
            for (size, filename) in sizes {
                if let resizedImage = resizeImage(image, to: CGSize(width: size, height: size)) {
                    let pngPath = iconsetPath.appendingPathComponent("\(filename).png")
                    if saveImageAsPNG(image: resizedImage, to: pngPath) {
                        print("Created \(filename).png at \(size)x\(size)")
                    }
                }
            }
            
            // 使用 iconutil 转换
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
            process.arguments = ["-c", "icns", "-o", outputIcnsPath.path, iconsetPath.path]
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            process.standardOutput = Pipe()
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputIcnsPath.path) {
                print("Successfully created AppIcon.icns via iconutil at: \(outputIcnsPath.path)")
                return outputIcnsPath.path
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("iconutil failed with status \(process.terminationStatus): \(errorMessage)")
            }
        } catch {
            print("Failed to create iconset: \(error)")
        }
        
        return nil
    }
    
    /// 尝试使用 sips 命令转换图片
    private func tryConvertImageViaSips(image: NSImage, outputDir: URL) -> String? {
        // 创建临时目录用于中间文件
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("DMGEditor_Sips_\(UUID().uuidString)")
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            let tempPngPath = tempDir.appendingPathComponent("AppIcon.png")
            let outputIcnsPath = outputDir.appendingPathComponent("AppIcon.icns")
            
            // 使用 NSImage 直接保存 PNG
            guard let tiffData = image.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
                print("Failed to convert image to PNG format")
                return nil
            }
            
            try pngData.write(to: tempPngPath)
            print("Created temporary PNG at: \(tempPngPath.path)")
            
            // 使用 sips 转换为 icns
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
            process.arguments = [
                "-s", "format", "icns",
                tempPngPath.path,
                "--out", outputIcnsPath.path
            ]
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            process.standardOutput = Pipe()
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: outputIcnsPath.path) {
                print("Successfully created AppIcon.icns via sips at: \(outputIcnsPath.path)")
                return outputIcnsPath.path
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("sips failed with status \(process.terminationStatus): \(errorMessage)")
                return nil
            }
        } catch {
            print("Failed to convert image via sips: \(error)")
            return nil
        }
    }
    
    /// 尝试保存图片为 PNG 格式
    private func trySaveImageAsPNG(image: NSImage, outputDir: URL) -> String? {
        let pngPath = outputDir.appendingPathComponent("AppIcon.png")
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            print("Failed to convert image to PNG")
            return nil
        }
        
        do {
            try pngData.write(to: pngPath)
            print("Successfully saved AppIcon.png at: \(pngPath.path)")
            return pngPath.path
        } catch {
            print("Failed to save PNG: \(error)")
            return nil
        }
    }
    
    /// 保存图片为 PNG 格式到指定路径
    private func saveImageAsPNG(image: NSImage, to path: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return false
        }
        
        do {
            try pngData.write(to: path)
            return true
        } catch {
            print("Failed to save PNG to \(path.path): \(error)")
            return false
        }
    }
    
    /// 调整图片尺寸
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
}
