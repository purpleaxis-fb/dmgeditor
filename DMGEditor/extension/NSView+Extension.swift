//
//  NSView+Extension.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

import AppKit

extension NSView{
    var center: CGPoint{
        return CGPoint(x: frame.origin.x + frame.size.width / 2, y: frame.origin.y + frame.size.height / 2)
    }
}
