import SwiftUI

struct DMGCanvasView: NSViewRepresentable {
    
    var config: DMGConfig
    var backgroundImageURL: URL?
    var clipItemsToBounds: Bool = true
    var selectedItemId: String?
    var scale: CGFloat
    var onItemMoved: ((String, CGPoint, CGPoint) -> Void)?
    var onItemTapped: ((String) -> Void)?
    var onItemAdd: ((URL) -> Void)?

    func makeNSView(context: Context) -> DMGCanvasNSView {
        let view = DMGCanvasNSView()
        view.clipItemsToBounds = clipItemsToBounds
        view.selectedItemId = selectedItemId
        view.onItemMoved = { id, point, iconCenter in
            // 1. 用回调上来的点，立即在 NSView 上校准最终位置
            view.updateItemPosition(id: id, position: point)
            
            // 2. 然后用这个点去更新上层 Model
            onItemMoved?(id, point, iconCenter)
        }
        view.onItemTapped = onItemTapped
        view.onItemAdd = onItemAdd
        return view
    }

    func updateNSView(_ nsView: DMGCanvasNSView, context: Context) {
        nsView.clipItemsToBounds = clipItemsToBounds
        nsView.selectedItemId = selectedItemId
        nsView.reload(items: config.items, scale: scale)
        
        // 更新背景图片
        if let imageURL = backgroundImageURL {
            let image = NSImage(contentsOf: imageURL)
            nsView.setBackgroundImage(image)
        } else {
            nsView.setBackgroundImage(nil)
        }
    }
}
