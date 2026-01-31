//
//  DMGExportConfig.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//

import Cocoa

struct DMGExportConfig {
    let dmgName: String
    let volumeName: String
    let windowSize: CGSize
    let appPosition: CGPoint
    let applicationsPosition: CGPoint
    let backgroundImagePath: String?
    let appPath: String
    let outputPath: String
    let extraFiles: [String] // README / LICENSE
}
