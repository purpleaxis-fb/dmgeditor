//
//  DMGExporter.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//
import Foundation

final class DMGExporter {

    static func export(config: DMGExportConfig) throws {
        let scriptPath = Bundle.main.path(
            forResource: "build_dmg",
            ofType: "sh"
        )!

        try ShellRunner.run(
            "/bin/bash",
            arguments: [
                scriptPath,
                config.dmgName,
                config.volumeName,
                "\(Int(config.windowSize.width))",
                "\(Int(config.windowSize.height))",
                "\(Int(config.appPosition.x))",
                "\(Int(config.appPosition.y))",
                "\(Int(config.applicationsPosition.x))",
                "\(Int(config.applicationsPosition.y))",
                config.backgroundImagePath ?? "",
                config.appPath,
                config.outputPath
            ]
        )
    }
}
