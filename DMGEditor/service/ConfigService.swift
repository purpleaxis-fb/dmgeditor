import Foundation

class ConfigService {
    
    static let shared = ConfigService()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        encoder.outputFormatting = .prettyPrinted
    }
    
    /// 将 DMGConfig 保存到指定 URL
    func saveConfig(_ config: DMGConfig, to url: URL) throws {
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
    }
    
    /// 从指定 URL 加载 DMGConfig
    func loadConfig(from url: URL) throws -> DMGConfig {
        let data = try Data(contentsOf: url)
        return try decoder.decode(DMGConfig.self, from: data)
    }
    
    /// 获取自动保存文件的 URL
    func getAutoSaveURL() -> URL? {
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let autoSaveURL = cacheDir
            .appendingPathComponent(Bundle.main.bundleIdentifier!)
            .appendingPathComponent("autosave.json")
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: autoSaveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        return autoSaveURL
    }
}
