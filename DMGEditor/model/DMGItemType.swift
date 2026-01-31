//
//  DMGItemType.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//

enum DMGItemType: String, Codable {
    case app
    case applications
    case file

    /// 是否是 DMG 必须存在的系统项
    var isRequired: Bool {
        switch self {
        case .app, .applications:
            return true
        case .file:
            return false
        }
    }

    /// 是否全局唯一
    var isUnique: Bool {
        switch self {
        case .app, .applications:
            return true
        case .file:
            return false
        }
    }
}
