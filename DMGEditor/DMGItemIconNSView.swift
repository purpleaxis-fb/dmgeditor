//
//  DMGItemIconNSView.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//

import SwiftUI

final class DMGItemIconNSView: NSImageView {

    let itemId: String
    var onMoved: ((String, CGPoint) -> Void)?
    var onTapped: ((String) -> Void)?
    var clipToBounds: Bool = true
    var isSelected: Bool = false {
        didSet {
            updateSelectionUI()
        }
    }

    private var dragStartInWindow: CGPoint = .zero
    private var dragStartFrame: CGRect = .zero
    private var hasDragged: Bool = false

    init(item: DMGItemModel) {
        self.itemId = item.id
        super.init(frame: NSRect(x: 0, y: 0, width: item.size.width, height: item.size.height))
        
        // 尝试加载图标：先检查是否是文件路径，否则使用系统图标名
        let iconImage = loadIcon(iconString: item.icon)
        image = iconImage
        imageScaling = .scaleProportionallyUpOrDown
        isEditable = false
        wantsLayer = true
    }
    
    /// 加载图标，支持文件路径和系统图标名
    private func loadIcon(iconString: String) -> NSImage? {
        // 如果 iconString 是有效的文件路径，尝试加载
        if iconString.hasPrefix("/") {
            if let image = NSImage(contentsOfFile: iconString) {
                return image
            }
        }
        
        // 否则尝试加载系统图标
        return NSImage(named: iconString)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func mouseDown(with event: NSEvent) {
        dragStartInWindow = event.locationInWindow
        dragStartFrame = frame
        hasDragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        hasDragged = true
        let currentLocationInWindow = event.locationInWindow
        let delta = CGPoint(
            x: currentLocationInWindow.x - dragStartInWindow.x,
            y: currentLocationInWindow.y - dragStartInWindow.y
        )
        
        var newOrigin = CGPoint(
            x: dragStartFrame.origin.x + delta.x,
            y: dragStartFrame.origin.y + delta.y
        )
        
        // 如果启用了边界限制，限制位置在父视图范围内
        if clipToBounds, let superview = superview {
            newOrigin = clampPositionToBounds(newOrigin, within: superview.bounds)
        }
        
        frame.origin = newOrigin
        
        // 实时通知位置变化（用于画布直接更新位置）
        let center = CGPoint(
            x: frame.midX,
            y: frame.midY
        )
        onMoved?(itemId, center)
    }

    override func mouseUp(with event: NSEvent) {
        if !hasDragged {
            // 如果没有拖动，则认为是点击
            onTapped?(itemId)
        } else {
            // 拖动结束，最后通知一次位置
            let center = CGPoint(
                x: frame.midX,
                y: frame.midY
            )
            onMoved?(itemId, center)
        }
    }
    
    /// 限制位置在父视图范围内
    private func clampPositionToBounds(_ position: CGPoint, within bounds: CGRect) -> CGPoint {
        let minX: CGFloat = 0
        let maxX: CGFloat = bounds.width - frame.width
        let minY: CGFloat = 0
        let maxY: CGFloat = bounds.height - frame.height
        
        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }
    
    /// 更新选中状态的 UI
    private func updateSelectionUI() {
        if isSelected {
            // 绘制蓝色边框表示选中
            layer?.borderColor = NSColor.systemBlue.cgColor
            layer?.borderWidth = 2.0
            layer?.shadowColor = NSColor.systemBlue.cgColor
            layer?.shadowOpacity = 0.3
            layer?.shadowRadius = 4.0
            layer?.backgroundColor = NSColor.systemGreen.cgColor
            layer?.shadowOffset = CGSize(width: 0, height: 0)
        } else {
            // 移除选中样式
            layer?.borderColor = NSColor.clear.cgColor
            layer?.borderWidth = 0
            layer?.shadowColor = NSColor.clear.cgColor
            layer?.shadowOpacity = 0
        }
    }
}
