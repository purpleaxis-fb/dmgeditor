# DMGEditor

一个用于创建 macOS DMG 磁盘镜像文件的图形化编辑器。使用可视化界面轻松设计专业的 DMG 安装程序。

## 功能特性

### 核心功能
- 可视化画板编辑器 - 实时预览 DMG 布局和图标位置
- 拖拽操作 - 支持拖拽添加 .app 应用、文件和文件夹
- 图标定位 - 可自由拖拽调整图标在 DMG 窗口中的位置
- 背景定制 - 支持自定义 DMG 窗口背景图片
- 卷图标设置 - 支持自定义卷标图标（icns/png/jpg）

### 项目管理
- 配置保存/加载 - 支持将配置保存为 .dmgconfig 文件
- 自动存档 - 支持自动保存配置（2秒防抖）
- 手动保存/加载 - 可手动保存和加载项目配置

### 导出功能
- 集成 create-dmg 脚本 - 使用业界标准的脚本生成 DMG 文件
- 实时构建日志 - 显示构建过程的实时输出
- 图标提取 - 自动从 .app 包中提取应用图标

### 支持的 Item 类型
| Item 类型 | 说明 |
|----------|------|
| .app | 主应用程序图标 |
| Applications | 应用程序文件夹快捷方式 |
| .file | 额外的文件或文件夹 |

## 系统要求

- macOS 系统
- Xcode 15 或更高版本（开发）
- Bash shell
- 标准 macOS 命令行工具（hdiutil、iconutil、sips 等）

## 快速开始

### 开发环境搭建
```bash
# 克隆仓库
git clone https://github.com/xtxk/DMGEditor.git
cd DMGEditor

# 打开 Xcode 项目
open DMGEditor.xcodeproj
```

### 使用应用

1. **选择应用** - 将 .app 文件拖入 App 区域
2. **配置 DMG 信息** - 设置卷名、窗口大小、图标大小
3. **设置输出路径** - 选择 DMG 文件保存位置
4. **添加背景图片**（可选）- 拖入背景图片文件
5. **设置卷图标**（可选）- 选择自定义卷标图标
6. **添加其他文件**（可选）- 拖入需要包含的文件
7. **调整布局** - 在画板中拖拽调整图标位置
8. **构建 DMG** - 点击 Build DMG 按钮生成文件

## 项目结构

```
DMGEditor/
├── DMGEditor/
│   ├── DMGEditorApp.swift          # 应用入口
│   ├── DMGEditorView.swift         # 主界面视图
│   ├── DMGEditorViewModel.swift    # 视图模型
│   ├── DMGSettingsPanel.swift      # 设置面板
│   ├── DMGItemEditPanel.swift      # Item 编辑面板
│   ├── DMGCanvasView.swift         # 画布视图
│   ├── DMGCanvasNSView.swift       # NSView 画布实现
│   ├── DMGFileDropView.swift       # 文件拖拽视图
│   ├── DMGItemView.swift           # Item 视图组件
│   ├── model/
│   │   ├── DMGConfig.swift         # DMG 配置模型
│   │   ├── DMGItemModel.swift      # Item 数据模型
│   │   └── DMGItemType.swift       # Item 类型定义
│   └── service/
│       ├── ConfigService.swift     # 配置保存/加载服务
│       └── CreateDMGService.swift  # DMG 构建服务
├── DMGEditorTests/                  # 单元测试
├── DMGEditorUITests/               # UI 测试
├── Resources/                       # 资源文件
│   ├── create-dmg                  # DMG 构建脚本
│   ├── template.applescript1       # AppleScript 模板
│   └── eula-resources-template.xml # EULA 模板
├── INTEGRATION_NOTES.md            # 集成说明（英文）
├── CREATE_DMG_GUIDE.md             # 功能开发指南（中文）
└── README.md                        # 英文版 README（默认）
```

## 技术栈

- **语言**: Swift 5.x
- **框架**: SwiftUI, AppKit
- **架构**: MVVM (Model-View-ViewModel)
- **构建工具**: Xcode
- **依赖**: create-dmg 脚本

## 贡献指南

欢迎提交 Issue 和 Pull Request。

## 许可证

[MIT License](LICENSE)

## 相关链接

- [create-dmg 官方仓库](https://github.com/create-dmg/create-dmg)

---

Made with ❤️ by xtxk
