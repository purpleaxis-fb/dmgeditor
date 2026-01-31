//
//  ShellRunner.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//
import Foundation

final class ShellRunner {
    static func run(
        _ command: String,
        arguments: [String] = []
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(
                domain: "ShellRunner",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Command failed"]
            )
        }
    }
}
