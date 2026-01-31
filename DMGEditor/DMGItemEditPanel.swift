//
//  DMGItemEditPanel.swift
//  DMGEditor
//
//  Created by xtxk on 2026/1/28.
//

import SwiftUI
import AppKit

struct DMGItemEditPanel: View {
    @Binding var config: DMGConfig
    let selectedItemId: String?
    let onRemoveItem: (String) -> Void
    
    var selectedItem: DMGItemModel? {
        guard let selectedItemId = selectedItemId else { return nil }
        return config.items.first(where: { $0.id == selectedItemId })
    }
    
    var body: some View {
        Group {
            if let item = selectedItem {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            if let image = loadImage(from: item.icon) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(6)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.fileName)
                                    .font(.headline)
                                Text(item.filePath)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                    }
                    
                    // Item Properties
                    VStack(spacing: 12) {
                        HStack {
                            Text("Position X")
                            Spacer()
                            TextField("", text: Binding(
                                get: { String(Int(item.position.x)) },
                                set: { if let v = Int($0) { updateItemPosition(id: item.id, x: CGFloat(v), y: item.position.y) } }
                            ))
                            .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Position Y")
                            Spacer()
                            TextField("", text: Binding(
                                get: { String(Int(item.position.y)) },
                                set: { if let v = Int($0) { updateItemPosition(id: item.id, x: item.position.x, y: CGFloat(v)) } }
                            ))
                            .frame(width: 80)
                        }
                        
                        Toggle("Hide file extension", isOn: Binding(
                            get: { item.hideExtension },
                            set: { updateItemHideExtension(id: item.id, hide: $0) }
                        ))
                    }
                    
                    // Delete Button
                    if !item.type.isRequired {
                        Button(role: .destructive) {
                            onRemoveItem(item.id)
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Item")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    Text("No Item Selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Click an item in the canvas to edit it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func updateItemPosition(id: String, x: CGFloat, y: CGFloat) {
        var updatedConfig = config
        updatedConfig.updatePosition(itemId: id, position: CGPoint(x: x, y: y))
        config = updatedConfig
    }
    
    private func updateItemHideExtension(id: String, hide: Bool) {
        var updatedConfig = config
        updatedConfig.updateItemHideExtension(itemId: id, hide: hide)
        config = updatedConfig
    }
    
    private func loadImage(from iconString: String) -> NSImage? {
        if iconString.hasPrefix("/") {
            return NSImage(contentsOfFile: iconString)
        }
        return NSImage(named: iconString)
    }
}
