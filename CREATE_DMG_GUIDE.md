# create-dmg 集成说明

## 概述
DMGEditor 已集成 `create-dmg` 脚本库（来自 https://github.com/create-dmg/create-dmg.git），用于生成专业级的 DMG 磁盘镜像。

## 集成位置
- **脚本位置**: `/DMGEditor/Resources/create-dmg`
- **集成服务**: `CreateDMGService.swift`
- **文件大小**: ~21KB

## 工作流程

### 1. 脚本定位
CreateDMGService 会按以下顺序查找 create-dmg 脚本：
1. Bundle Resources/create-dmg
2. 应用包 Contents/Resources/create-dmg
3. 系统 PATH 中的 create-dmg

### 2. 参数构建
根据 DMGConfig 和所有 items 自动构建命令参数：

```bash
/usr/bin/env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
create-dmg \
  --support-dir /path/to/cache/DMGEditor/support \
  --hdiutil-verbose \
  --volname "Volume Name"              # 从 config.volumeName
  --window-size 600 400                # 从 config.windowSize
  --icon-size 96                       # 从 config.iconSize
  --volicon /path/to/volume.icns       # 从 config.volumeIconPath（如果设置）
  --background /path/to/bg.png         # 从 config.processedBackgroundImageURL（如果设置）
  --icon "App.app" 150 200             # 从 .app type items（使用 iconCenter 坐标）
  --app-drop-link 450 200              # 从 .applications type items（使用 iconCenter 坐标）
  --add-file "Readme.txt" /path 300 300 # 从 .file type items（使用 iconCenter 坐标）
  --hide-extension "Readme.txt"       # 隐藏文件扩展名（如果设置）
  Output.dmg                           # config.dmgName
  /path/to/source                      # config.appPath
```

### 3. Item 映射

| Item 类型 | create-dmg 参数 | 说明 |
|----------|----------------|------|
| `.app` | `--icon {name} {x} {y}` | 应用图标定位（使用 iconCenter） |
| `.applications` | `--app-drop-link {x} {y}` | 应用程序文件夹快捷方式（使用 iconCenter） |
| `.file` | `--add-file {name} {path} {x} {y}` | 额外的文件/文件夹（使用 iconCenter） |

## 使用示例

### 步骤 1：配置 DMG
在 DMGEditor 中：
- 选择应用（.app）
- 设置卷名："My Awesome App"
- 设置窗口大小：600×400
- 设置图标大小：96
- 选择背景图片（自动处理为窗口大小）
- 选择卷图标（支持 .icns、.png、.jpg）
- 拖放应用到位置 (150, 200)
- 拖放 Applications 文件夹到位置 (450, 200)
- 添加 README 文件到位置 (300, 350)
- 设置输出路径（默认 Desktop）

### 步骤 2：构建 DMG
点击"Build DMG"按钮 → CreateDMGService 执行：
```
✅ Found create-dmg at: /path/to/create-dmg
📋 Build Configuration:
   App Path: /Applications/MyApp.app
   App Path Exists: ✅
   DMG Name: MyApp
   Volume Name: MyApp Installer
   Output Path: /Users/username/Desktop
   Output Dir Exists: ✅
   Output Dir Writable: ✅
   Support dir: /Users/username/Library/Caches/DMGEditor/support
📝 Command arguments:
/usr/bin/env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ...
✅ DMG 创建成功: /Users/username/Desktop/MyApp.dmg
```

### 步骤 3：输出
- DMG 文件生成在指定输出路径
- 控制台输出实时日志
- 包含所有指定的项目、背景和图标
- 自动清理临时文件（rw.*.dmg）

## 已实现功能

### 核心功能
- ✅ create-dmg 脚本集成
- ✅ 可视化画板编辑器（DMGCanvasView）
- ✅ 拖拽添加 .app、文件、文件夹（DMGFileDropView）
- ✅ 图标位置拖拽调整
- ✅ 限制 items 在画板内
- ✅ 背景图片自动处理（等比缩放居中）
- ✅ 卷图标设置（支持格式转换）

### 图标处理
- ✅ 从 .app bundle 提取图标
  - AppIcon.icns
  - Assets.car（使用 xcrun assetutil）
  - NSWorkspace 备选方案
- ✅ 图标格式转换（PNG → ICNS）
  - iconutil（生成 iconset 并转换）
  - sips（备用转换方案）
  - PNG 备选方案
- ✅ 系统图标获取
- ✅ 图标缓存管理

### 配置管理
- ✅ JSON 格式的配置保存/加载（.dmgconfig）
- ✅ 自动存档功能（2秒防抖）
- ✅ 手动保存/加载项目
- ✅ 隐藏文件扩展名
- ✅ 输出路径设置

### UI 功能
- ✅ Settings 面板（DMGSettingsPanel）
  - App 设置
  - Archive 设置
  - DMG Info 设置
  - Volume Icon 设置
  - Output 设置
  - Window 设置
  - Background 设置
  - Add Items 设置
- ✅ Edit Item 面板（DMGItemEditPanel）
  - 位置编辑（X/Y）
  - 隐藏扩展名切换
  - 删除 Item（非必需项）
- ✅ 预览画布功能（DMGCanvasView + DMGCanvasNSView）
  - 自适应缩放显示
  - 图标中心点精确定位
  - 实时拖拽反馈
- ✅ Build Log 显示
  - 实时输出
  - 清除功能
  - 文本选择

## 必要条件
- macOS 系统（已安装标准命令行工具）
- Bash shell
- 必要的 create-dmg 依赖：hdiutil、iconutil、sips 等（macOS 标准工具）

## 故障排除

### 脚本未找到
```
❌ create-dmg script not found
   Tried locations:
   1. Bundle Resources/create-dmg
   2. App bundle Contents/Resources/create-dmg
   3. System PATH
```

**解决方案**：
```bash
# 检查脚本存在性和权限
ls -la /Users/xtxk/Documents/DMGEditor/DMGEditor/Resources/create-dmg

# 恢复执行权限（如需要）
chmod +x /Users/xtxk/Documents/DMGEditor/DMGEditor/Resources/create-dmg
```

### 构建失败
- ✓ 检查所有文件路径是否存在
- ✓ 验证背景图片格式有效
- ✓ 确保输出目录可写
- ✓ 检查 DMGConfig 参数是否合理
- ✓ 检查磁盘空间是否充足
- ✓ 验证 support 文件存在（template.applescript、eula-resources-template.xml）

### 图标提取失败
```
⚠️ Could not extract icon from app:
   - Info.plist not found
   - No .icns files in Resources
   - Fallback to system icon: app.circle.fill
```

**解决方案**：
- 检查 .app bundle 结构
- 确保包含 AppIcon.icns 或 Assets.car
- 系统会自动使用 NSWorkspace 获取图标

## 相关文件
- `CreateDMGService.swift` - 集成实现
- `DMGEditor/Resources/create-dmg` - 脚本主程序
- `DMGEditor/Resources/template.applescript1` - AppleScript 模板
- `DMGEditor/Resources/eula-resources-template.xml` - EULA 模板
- `DMGEditor/DMGConfig.swift` - 配置模型
- `DMGEditor/DMGItemModel.swift` - Item 模型
- `DMGEditor/DMGEditorViewModel.swift` - 视图模型
- `DMGEditor/DMGCanvasView.swift` - 画布视图
- `DMGEditor/DMGSettingsPanel.swift` - 设置面板
- `DMGEditor/DMGItemEditPanel.swift` - Item 编辑面板
- `INTEGRATION_NOTES.md` - 集成详情

## 参考资源
- create-dmg 仓库: https://github.com/create-dmg/create-dmg

---

# 功能开发指南

## 1. ✅ 存档和恢复配置（已完成）

### 功能说明
支持保存和加载 DMG 配置文件，避免每次都重新设置。

### 已实现功能
- ✅ JSON 格式的配置保存/加载（ConfigService.swift）
- ✅ 自动存档功能（2秒防抖）
- ✅ 手动保存/加载项目（DMGEditorViewModel.swift）
- ✅ 支持加载时重新生成背景图

### UI 需求
- ✅ Settings 面板中的 Archive 设置
- ✅ Enable Auto-Save 开关
- ✅ Save/Load 按钮工具栏

### 使用方式
```swift
// 手动保存项目
viewModel.saveProject(showAlert: { title, msg in
    alertManager.showAlert(title: title, message: msg)
})

// 手动加载项目
viewModel.loadProject(showAlert: { title, msg in
    alertManager.showAlert(title: title, message: msg)
})
```

---

## 2. ✅ 效果预览（已完成）

### 功能说明
在构建前实时预览最终 DMG 的效果。

### 已实现功能
- ✅ 可视化画板编辑器（DMGCanvasView + DMGCanvasNSView）
- ✅ 实时显示背景图片、图标位置、文本标签
- ✅ 自适应缩放显示（GeometryReader 计算）
- ✅ 实时拖拽反馈
- ✅ 图标中心点精确定位（iconCenter）
- ✅ 限制 items 在画板内（clipItemsToBounds）

### UI 需求
- ✅ 主画布区域（右侧）
- ✅ 自动计算缩放比例
- ✅ Items 拖拽移动
- ✅ 点击选中 Items

---

## 3. ⭕ Icon 替换或变更（未实现）

### 功能说明
允许用户自定义替换 Item 的图标（而不仅限于系统图标）。

### 实现计划
```swift
struct DMGItemModel {
    var icon: String  // 当前为系统图标名称或路径
    var customIconPath: URL?  // 新增：自定义图标路径
}
```

### UI 需求
- ⭕ Item 编辑面板添加 "Change Icon..." 按钮
- ⭕ 支持选择本地图标文件 (.png, .icns, .tiff)
- ⭕ 实时预览新图标效果

---

## 4. ⭕ Item 列表显示文件名（部分实现）

### 功能说明
在 Item 编辑面板中显示选中 Item 的文件名。

### 已实现功能
- ✅ Edit Item 面板显示选中 Item 的文件名
- ✅ 显示 Item 图标预览
- ✅ 显示文件路径
- ✅ 支持位置编辑（X/Y）
- ✅ 支持隐藏文件扩展名
- ✅ 支持删除非必需 Item

### 未实现功能
- ⭕ 完整的 Item 列表视图
- ⭕ 拖拽重排序
- ⭕ 列表中直接编辑

### UI 需求
- ⭕ 列表格式：[Icon] 文件名 [编辑按钮] [删除按钮]
- ⭕ 支持拖拽重排序
- ⭕ 点击选中后在 Canvas 中高亮显示

---

## 5. ⭕ Applications 快捷链接样式定制（未实现）

### 功能说明
允许自定义 Applications 文件夹快捷方式的外观和标签。

### 实现计划
```swift
struct DMGItemModel {
    // 当 type == .applications 时
    var label: String? = "Applications"  // 快捷链接的显示文本
    var style: ApplicationLinkStyle = .folder  // 样式枚举
}

enum ApplicationLinkStyle {
    case folder      // 文件夹样式（默认）
    case link        // 链接快捷方式
    case alias       // 别名样式
    case custom(String)  // 自定义文本标签
}
```

### UI 需求
- ⭕ Applications Item 编辑时显示样式选择器
- ⭕ 实时预览样式变化
- ⭕ 支持自定义标签文本

---

## 6. ✅ App Icon 显示异常处理（已完成）

### 功能说明
当应用 Icon 无法显示时的备用方案。

### 已实现功能
- ✅ 多层 fallback 机制（extractAppIcon 方法）
  1. 尝试从 Contents/Resources/AppIcon.icns 获取
  2. 尝试在 Contents/Resources/ 查找其他 .icns 文件
  3. 尝试从 Assets.car 提取（使用 xcrun assetutil）
  4. 尝试使用 NSWorkspace.shared.icon(forFiles:)
  5. 失败则返回默认图标 "app.fill"
- ✅ 图标格式转换支持
  - iconutil（生成 iconset 并转换）
  - sips（备用转换方案）
  - PNG 备选方案
- ✅ 诊断日志输出

### 实现方式
```swift
// 在 DMGConfig.swift 中实现
private func extractAppIcon(from appURL: URL) -> String {
    // 1. 查找 AppIcon.icns
    // 2. 查找其他 .icns 文件
    // 3. 从 Assets.car 提取
    // 4. 使用 NSWorkspace
    // 5. 返回默认图标
}
```

### 诊断日志
```
Attempting to extract icon from Assets.car for: MyApp.app
Successfully extracted icon from Assets.car: /path/to/icon.icns
No icon found, using default icon for: MyApp.app
```

---

## 7. ⭕ 多语言本地化（未实现）

### 功能说明
支持中文、英文等多语言界面。

### 实现计划

**支持语言**：
- 🇨🇳 简体中文 (Simplified Chinese)
- 🇬🇧 英文 (English)
- 🇹🇼 繁体中文 (Traditional Chinese) - 可选

**关键字符串本地化**：
```swift
// 使用 NSLocalizedString 替代硬编码字符串
Button(NSLocalizedString("Build DMG", comment: "Build button label")) { ... }

// 或使用 .strings 文件
// Localizable.strings (Chinese)
"Build DMG" = "构建 DMG";
"Volume Name" = "卷名";
"Output Path" = "输出路径";
```

**实现步骤**：
1. ⭕ 创建 `Localizable.strings` 和 `Localizable.strings (zh-Hans)`
2. ⭕ 替换所有 UI 文本为 `NSLocalizedString(...)`
3. ⭕ 系统自动根据系统语言选择

---

## 8. ✅ 画板和实际尺寸的映射关系（已完成）

### 功能说明
建立画板尺寸与最终 DMG 窗口尺寸的精确映射。

### 核心概念

**三个坐标系**：
1. **Canvas 坐标系** - UI 画板中的显示坐标
2. **DMG 坐标系** - 最终 DMG 窗口中的实际坐标
3. **屏幕坐标系** - 用户屏幕上的 1:1 显示

### 已实现功能
- ✅ 自适应缩放显示（GeometryReader 计算）
- ✅ 坐标转换（Canvas ↔ DMG）
- ✅ 图标中心点精确定位（iconCenter）
- ✅ 拖拽时实时坐标转换
- ✅ 限制 items 在画板内（clipItemsToBounds）

### 映射计算

```swift
/// 配置中的尺寸设置
config.windowSize = CGSize(width: 600, height: 400)  // DMG 最终窗口大小

/// 画板显示设置（在 DMGEditorView.swift 中）
let availableSize = geometry.size
let scaleX = availableSize.width / configSize.width
let scaleY = availableSize.height / configSize.height
let scale = min(scaleX, scaleY, 1.0)  // 缩放因子

/// 坐标转换（在 DMGCanvasNSView.swift 中）
let scaledPosition = CGPoint(x: item.position.x * scale, y: item.position.y * scale)
let originalPoint = CGPoint(x: point.x / scale, y: point.y / scale)
```

### UI 需求

**预览控制面板**：
- ✅ 自适应缩放显示
- ✅ Items 拖拽移动
- ✅ 点击选中 Items

### 未实现功能
- ⭕ 1:1 预览窗口
- ⭕ 手动缩放控制（50%, 75%, 100%）
- ⭕ 显示当前缩放比例
- ⭕ 1:1 预览按钮

### 实现步骤

1. ✅ 在 DMGCanvasView 中实现坐标转换
2. ✅ 在 DMGCanvasNSView 中实现缩放显示
3. ⭕ 创建 DMGPreviewWindow 用于 1:1 预览
4. ⭕ 添加预览窗口切换按钮
5. ⭕ 实现缩放控制的 UI 组件

### 验证

```swift
// 测试坐标映射的准确性
let scale = 0.667
let testPoint = CGPoint(x: 300, y: 200)  // 画板坐标
let actualPoint = canvasToActual(point: testPoint)
// 应该得到: (450, 300) = (300/0.667, 200/0.667)

let backToCanvas = actualToCanvas(point: actualPoint)
// 应该回到: (300, 200)
```

---

## 优先级建议

| 功能 | 状态 | 优先级 | 复杂度 | 预计工时 |
|-----|------|--------|--------|----------|
| 1. 存档和恢复配置 | ✅ 完成 | 🔴 高 | 中 | 2小时 |
| 2. 效果预览 | ✅ 完成 | 🟡 中 | 高 | 2小时 |
| 4. Item 列表显示文件名 | ⭕ 部分完成 | 🟡 中 | 低 | 1小时 |
| 6. App Icon 异常处理 | ✅ 完成 | 🔴 高 | 中 | 1.5小时 |
| 8. 画板尺寸映射 | ✅ 完成 | 🟡 中 | 高 | 3小时 |
| 5. Applications 样式定制 | ⭕ 未实现 | 🟢 低 | 中 | 2小时 |
| 3. Icon 替换 | ⭕ 未实现 | 🟢 低 | 中 | 2小时 |
| 7. 多语言本地化 | ⭕ 未实现 | 🟢 低 | 低 | 1小时 |

## 待开发功能

### 高优先级
1. ⭕ **1:1 预览窗口** - 新增独立窗口显示实际大小的 DMG 预览
2. ⭕ **手动缩放控制** - 支持 50%、75%、100% 等缩放选项
3. ⭕ **完整 Item 列表** - 显示所有 Item 的列表视图，支持拖拽重排序

### 中优先级
4. ⭕ **Icon 替换** - 允许用户自定义替换 Item 的图标
5. ⭕ **Applications 样式定制** - 允许自定义 Applications 文件夹快捷方式的外观

### 低优先级
6. ⭕ **多语言本地化** - 支持中文、英文等多语言界面

## 已知问题

1. **1:1 预览** - 当前只有自适应缩放，没有 1:1 预览功能
2. **Item 列表** - 当前只有选中 Item 的编辑面板，没有完整的 Item 列表
3. **Icon 自定义** - 无法自定义替换 Item 的图标
4. **Applications 样式** - 无法自定义 Applications 文件夹的样式

## 技术债务

1. **坐标系统** - 坐标转换逻辑分散在多处，建议统一管理
2. **图标缓存** - 图标缓存机制可以进一步优化
3. **错误处理** - 部分错误处理可以更加完善
4. **测试覆盖** - 缺少单元测试和集成测试