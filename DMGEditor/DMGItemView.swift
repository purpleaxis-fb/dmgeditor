//
//  DMGItemView.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/29.
//

import SwiftUI
import AppKit
import Foundation
import CoreGraphics

final class DMGItemView: NSView {

    let itemId: String
    var onMoved: ((String, CGPoint, CGPoint) -> Void)?
    var onTapped: ((String) -> Void)?
    var clipToBounds: Bool = true
    var isSelected: Bool = false {
        didSet {
            updateSelectionUI()
        }
    }

    private let imageView: NSImageView
    private let textField: NSTextField
    private let iconSelectionLayer = CALayer()
    private let textSelectionLayer = CALayer()

    private var dragStartInSuperview: CGPoint = .zero
    private var dragStartFrame: CGRect = .zero
    private var hasDragged: Bool = false

    init(item: DMGItemModel, scale: CGFloat) {
        self.itemId = item.id
        
        // 创建图标视图
        imageView = NSImageView(frame: .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = DMGItemView.loadIcon(iconString: item.icon)
        
        // 创建文本标签
        let displayName = item.hideExtension ? (item.fileName as NSString).deletingPathExtension : item.fileName
        textField = NSTextField(labelWithString: displayName)
        textField.alignment = .center
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.font = NSFont.systemFont(ofSize: 12)
        textField.textColor = .black

        super.init(frame: .zero)
        
        wantsLayer = true
        
        // 配置并添加选择图层
        iconSelectionLayer.isHidden = true
        layer?.addSublayer(iconSelectionLayer)

        textSelectionLayer.backgroundColor = NSColor.systemBlue.cgColor
        textSelectionLayer.isHidden = true
        layer?.addSublayer(textSelectionLayer)
        
        addSubview(imageView)
        addSubview(textField)
        
        // 确保子视图渲染在它们各自的选择图层之上
        imageView.wantsLayer = true
        imageView.layer?.zPosition = 1
        
        textField.wantsLayer = true
        textField.layer?.zPosition = 1
        
        // 初始布局
        updateLayout(size: item.size, scale: scale)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with item: DMGItemModel, scale: CGFloat) {
        let newImage = DMGItemView.loadIcon(iconString: item.icon)
        if imageView.image != newImage {
            imageView.image = newImage
        }

        let displayName = item.hideExtension ? (item.fileName as NSString).deletingPathExtension : item.fileName
        if textField.stringValue != displayName {
            textField.stringValue = displayName
        }

        updateLayout(size: item.size, scale: scale)
    }
    
    private func iconCenter() -> CGPoint{
        return imageView.center
    }

    private func updateLayout(size: CGSize, scale: CGFloat) {
        let selectionPadding: CGFloat = 6.0
        let scaledSelectionPadding: CGFloat = selectionPadding * scale
        
        // 根据macOS系统调研：
        // 1. size (item.size) 是选定框的大小，即 iconSize
        // 2. 实际显示的icon大小 = 选定框大小 - 2 * selectionPadding
        let actualIconSize = CGSize(width: size.width - 2 * selectionPadding, height: size.height - 2 * selectionPadding)
        
        // 缩放后的实际icon大小
        let scaledIconSize = CGSize(width: actualIconSize.width * scale, height: actualIconSize.height * scale)
        
        let textHeight: CGFloat = 18 * scale
        let spacing: CGFloat = 4 * scale

        textField.font = NSFont.systemFont(ofSize: 12 * scale)
        textField.sizeToFit()

        let finalWidth = max(scaledIconSize.width, textField.frame.width)
        // frame高度 = 实际icon高度（缩放后） + 间距 + 文本高度
        frame.size = CGSize(width: finalWidth, height: size.height + spacing + textHeight)
        
        // 水平居中图标
        imageView.frame = CGRect(
            x: (finalWidth - scaledIconSize.width) / 2,
            y: textHeight + spacing + scaledSelectionPadding,
            width: scaledIconSize.width,
            height: scaledIconSize.height
        )

        // 水平居中文本标签
        let textFieldFrame = CGRect(
            x: (finalWidth - textField.frame.width) / 2,
            y: 0,
            width: textField.frame.width,
            height: textHeight
        )
        textField.frame = textFieldFrame
        
        // --- 更新选择图层 ---
        
        // 图标选择样式：选定框的大小就是 icon size
        // 所以选择图层应该围绕 icon 区域向外扩展 padding
        let iconSelectionFrame = CGRect(
            x: imageView.frame.origin.x - scaledSelectionPadding,
            y: imageView.frame.origin.y - scaledSelectionPadding,
            width: scaledIconSize.width + 2 * scaledSelectionPadding,
            height: scaledIconSize.height + 2 * scaledSelectionPadding
        )
        
        iconSelectionLayer.frame = iconSelectionFrame
        iconSelectionLayer.cornerRadius = 6 * scale
        iconSelectionLayer.borderColor = NSColor.white.withAlphaComponent(0.8).cgColor
        iconSelectionLayer.borderWidth = 1.0 * scale
        iconSelectionLayer.backgroundColor = NSColor.black.withAlphaComponent(0.1).cgColor

        // 文本选择样式
        let textSelectionHPadding: CGFloat = 0 * scale
        let textSelectionVPadding: CGFloat = 0 * scale
        textSelectionLayer.frame = textFieldFrame.insetBy(dx: -textSelectionHPadding, dy: -textSelectionVPadding)
        textSelectionLayer.cornerRadius = 4.0 * scale
    }
    
    

    static private func loadIcon(iconString: String) -> NSImage? {
        if iconString.hasPrefix("/") {
            if let image = NSImage(contentsOfFile: iconString) {
                return image
            }
        }
        return NSImage(named: iconString)
    }

    override func mouseDown(with event: NSEvent) {
        guard let superview = self.superview else { return }
        dragStartInSuperview = superview.convert(event.locationInWindow, from: nil)
        dragStartFrame = frame
        hasDragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let superview = self.superview else { return }
        hasDragged = true
        let currentLocationInSuperview = superview.convert(event.locationInWindow, from: nil)
        
        let delta = CGPoint(
            x: currentLocationInSuperview.x - dragStartInSuperview.x,
            y: currentLocationInSuperview.y - dragStartInSuperview.y
        )
        
        var newOrigin = CGPoint(
            x: dragStartFrame.origin.x + delta.x,
            y: dragStartFrame.origin.y + delta.y
        )
        
        if clipToBounds {
            newOrigin = clampPositionToBounds(newOrigin, within: superview.bounds)
        }
        
        frame.origin = newOrigin
    }

    override func mouseUp(with event: NSEvent) {
        if !hasDragged {
            onTapped?(itemId)
        } else {
            // 直接传递当前的origin，避免center计算导致的精度问题
            let currentOrigin = frame.origin
            onMoved?(itemId, currentOrigin, iconCenter())
        }
    }
    
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
    
    private func updateSelectionUI() {
        // 清除主视图上的任何旧图层样式
        layer?.borderColor = NSColor.clear.cgColor
        layer?.borderWidth = 0
        layer?.shadowOpacity = 0
        
        if isSelected {
            iconSelectionLayer.isHidden = false
            textSelectionLayer.isHidden = false
            textField.textColor = .white
        } else {
            iconSelectionLayer.isHidden = true
            textSelectionLayer.isHidden = true
            textField.textColor = .black
        }
    }
}
