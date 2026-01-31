//
//  DMGCanvasNSView.swift
//  DMGEditor
//
//  Created by freeblow on 2026/1/27.
//

import AppKit

/// 一个自定义的 NSImageView，它会忽略所有鼠标事件，
/// 允许事件“穿透”到它下方的视图。
fileprivate final class PassthroughImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // 返回 nil 表示不处理任何鼠标事件
        return nil
    }
}

final class DMGCanvasNSView: NSView {
   
    var onItemMoved: ((String, CGPoint, CGPoint) -> Void)?
    var onItemTapped: ((String) -> Void)?
    var onItemAdd: ((URL) -> Void)?
    var clipItemsToBounds: Bool = true
    var selectedItemId: String?
    private var itemViews: [String: DMGItemView] = [:]
    private var currentScale: CGFloat = 1.0
    
    override var isFlipped: Bool {
        return true
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingPasteboard.types?.contains(.fileURL) == true {
            return .copy
        }
        return []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboardItem = sender.draggingPasteboard.pasteboardItems?.first,
              let fileURLString = pasteboardItem.string(forType: .fileURL),
              let url = URL(string: fileURLString) else {
            return false
        }
        
        onItemAdd?(url)
        return true
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor =
        NSColor.controlBackgroundColor
            .withAlphaComponent(0.15)
            .cgColor
        layer?.contentsGravity = .resizeAspectFill
        layer?.masksToBounds = true
    }
    
    func updateFrame(with size: CGSize, scale: CGFloat) {
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        if frame.size != newSize {
            setFrameSize(newSize)
        }
    }
    


    
    func setBackgroundImage(_ image: NSImage?) {
        layer?.contents = image
        updateBackgroundCrop()
    }
    
    private func updateBackgroundCrop() {
        guard
            let image = layer?.contents as? NSImage,
            let rep = image.representations.first
        else { return }
        
        let imageSize = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        let viewSize = bounds.size
        
        let imageRatio = imageSize.width / imageSize.height
        let viewRatio = viewSize.width / viewSize.height
        
        var contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        if imageRatio > viewRatio {
            // 图片更宽 → 横向裁剪
            let scale = viewRatio / imageRatio
            contentsRect.origin.x = (1 - scale) / 2
            contentsRect.size.width = scale
        } else {
            // 图片更高 → 纵向裁剪
            let scale = imageRatio / viewRatio
            contentsRect.origin.y = (1 - scale) / 2
            contentsRect.size.height = scale
        }
        
        layer?.contentsRect = contentsRect
    }
    
    func updatePositions(app: CGPoint, applications: CGPoint) {
        //        appIcon.setFrameOrigin(
        //            CGPoint(x: app.x - 32, y: app.y - 32)
        //        )
        //        applicationsIcon.setFrameOrigin(
        //            CGPoint(x: applications.x - 32, y: applications.y - 32)
        //        )
    }
    
    override func layout() {
        super.layout()
        updateBackgroundCrop()
    }
}

extension DMGCanvasNSView {
    
    func reload(items: [DMGItemModel], scale: CGFloat) {
        currentScale = scale
        
        // 清除不存在的视图
        let itemIds = Set(items.map { $0.id })
        for (id, view) in itemViews {
            if !itemIds.contains(id) {
                view.removeFromSuperview()
                itemViews.removeValue(forKey: id)
            }
        }
        
        // 更新或创建视图
        for item in items {
            let scaledPosition = CGPoint(x: item.position.x * scale, y: item.position.y * scale)

            if let existingView = itemViews[item.id] {
                existingView.update(with: item, scale: scale)
                
                // 更新位置（position是原始左上角坐标）
                let scaledPosition = CGPoint(x: item.position.x * scale, y: item.position.y * scale)
                let finalOrigin = clipItemsToBounds ? 
                    clampPositionToBounds(scaledPosition, iconSize: existingView.frame.size) : 
                    scaledPosition
                existingView.frame.origin = finalOrigin
                
                // 更新边界限制设置
                existingView.clipToBounds = clipItemsToBounds
                
                // 更新选中状态
                existingView.isSelected = (item.id == selectedItemId)
            } else {
                // 创建新视图
                let itemView = DMGItemView(item: item, scale: scale)
                itemView.clipToBounds = clipItemsToBounds
                itemView.isSelected = (item.id == selectedItemId)
                
                // 设置初始位置（position已经是左上角坐标）
                let finalOrigin = clipItemsToBounds ? 
                    clampPositionToBounds(scaledPosition, iconSize: itemView.frame.size) : 
                    scaledPosition
                itemView.frame.origin = finalOrigin
                
                itemView.onMoved = { [weak self] id, point, iconCenter in
                    guard let self = self else { return }
                    // point现在是origin，转换为原始坐标
                    let originalPoint = CGPoint(x: point.x / scale, y: point.y / scale)
                    let mItem = itemViews[id]
                    //item坐标转为画板坐标
                    let currentIconPoint = mItem?.convert(iconCenter, to: self) ?? CGPoint.zero
                    let oriIconCenter = CGPoint(x: currentIconPoint.x / scale, y: currentIconPoint.y / scale)
                    self.onItemMoved?(id, originalPoint, oriIconCenter)
                }
                
                itemView.onTapped = { [weak self] id in
                    self?.onItemTapped?(id)
                }
                
                addSubview(itemView)
                itemViews[item.id] = itemView
            }
        }
    }
    
    func updateItemPosition(id: String, position: CGPoint) {
        guard let itemView = itemViews[id] else { return }

        // position是原始坐标（已经除以scale），需要转换为画布坐标
        let canvasOrigin = CGPoint(x: position.x * currentScale, y: position.y * currentScale)
        
        if clipItemsToBounds {
            let clampedOrigin = clampPositionToBounds(canvasOrigin, iconSize: itemView.frame.size)
            itemView.frame.origin = clampedOrigin
        } else {
            itemView.frame.origin = canvasOrigin
        }
    }
    
    /// 限制位置在画板范围内
    private func clampPositionToBounds(_ position: CGPoint, iconSize: CGSize) -> CGPoint {
        let canvasBounds = bounds
        let iconWidth = iconSize.width
        let iconHeight = iconSize.height
        
        let minX: CGFloat = 0
        let maxX: CGFloat = canvasBounds.width - iconWidth
        let minY: CGFloat = 0
        let maxY: CGFloat = canvasBounds.height - iconHeight
        
        return CGPoint(
            x: min(max(position.x, minX), maxX),
            y: min(max(position.y, minY), maxY)
        )
    }
}
