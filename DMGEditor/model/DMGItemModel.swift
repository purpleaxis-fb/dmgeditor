//
//  DMGItemModel.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//
import SwiftUI

struct DMGItemModel: Codable, Identifiable {
    let type: DMGItemType
    var size: CGSize = CGSize(width: 64, height: 64)
    var position: CGPoint
    var iconCenter: CGPoint = .zero
    var filePath: String
    var fileName: String
    var icon: String
    var id: String
    var hideExtension: Bool = false
    
    /// DMGItemView 内部图标相对于 view 左上角的 Y 偏移量（固定值）
    /// = textHeight(18) + spacing(8) = 26
    static let iconOffsetY: CGFloat = 26
    
    init(
        type: DMGItemType,
        position: CGPoint,
        filePath: String,
        fileName: String,
        icon: String
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.position = position
        self.filePath = filePath
        self.fileName = fileName
        self.icon = icon
        // 自动计算 iconCenter
        self.iconCenter = CGPoint(
            x: position.x + size.width / 2,
            y: position.y + Self.iconOffsetY + size.height / 2
        )
    }
    
    /// 从归档数据解码，手动处理以支持向后兼容
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(DMGItemType.self, forKey: .type)
        size = try container.decodeIfPresent(CGSize.self, forKey: .size) ?? CGSize(width: 64, height: 64)
        position = try container.decodeIfPresent(CGPoint.self, forKey: .position) ?? .zero
        
        // 兼容旧版本：检查是否存在 iconCenter，不存在则根据 position 计算
        if let storedIconCenter = try container.decodeIfPresent(CGPoint.self, forKey: .iconCenter) {
            iconCenter = storedIconCenter
        } else {
            // 旧版本数据，根据 position 和 size 计算
            iconCenter = CGPoint(
                x: position.x + size.width / 2,
                y: position.y + Self.iconOffsetY + size.height / 2
            )
        }
        
        filePath = try container.decodeIfPresent(String.self, forKey: .filePath) ?? ""
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? ""
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? ""
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        hideExtension = try container.decodeIfPresent(Bool.self, forKey: .hideExtension) ?? false
    }
    
    enum CodingKeys: String, CodingKey {
        case type, size, position, iconCenter, filePath, fileName, icon, id, hideExtension
    }
}
