# DMGEditor

A visual editor for creating macOS DMG (Disk Image) files. Design professional DMG installers with an intuitive visual interface.

[中文版本 (Chinese Version)](README_CN.md)

## Features

### Core Features
- **Visual Canvas Editor** - Real-time preview of DMG layout and icon positioning
- **Drag & Drop Support** - Easily add .app applications, files, and folders via drag and drop
- **Icon Positioning** - Freely drag and adjust icon positions within the DMG window
- **Background Customization** - Support for custom DMG window background images
- **Volume Icon** - Support for custom volume icons (icns/png/jpg)

### Project Management
- **Configuration Save/Load** - Save configurations as .dmgconfig files
- **Auto-Save** - Automatic configuration saving (with 2-second debounce)
- **Manual Save/Load** - Manually save and load project configurations

### Export Functionality
- **create-dmg Integration** - Uses industry-standard create-dmg script to generate DMG files
- **Real-time Build Logs** - Displays real-time output during the build process
- **Icon Extraction** - Automatically extracts app icons from .app bundles

### Supported Item Types
| Item Type | Description |
|-----------|-------------|
| .app | Main application icon |
| Applications | Applications folder shortcut |
| .file | Additional files or folders |

## System Requirements

- macOS System
- Xcode 15 or later (for development)
- Bash shell
- Standard macOS command line tools (hdiutil, iconutil, sips, etc.)

## Quick Start

### Development Environment Setup
```bash
# Clone the repository
git clone https://github.com/xtxk/DMGEditor.git
cd DMGEditor

# Open in Xcode
open DMGEditor.xcodeproj
```

### Using the App

1. **Select Application** - Drag a .app file into the App area
2. **Configure DMG Info** - Set volume name, window size, and icon size
3. **Set Output Path** - Choose where to save the DMG file
4. **Add Background Image** (optional) - Drag in a background image file
5. **Set Volume Icon** (optional) - Select a custom volume icon
6. **Add Other Files** (optional) - Drag in additional files to include
7. **Adjust Layout** - Drag icons on the canvas to adjust their positions
8. **Build DMG** - Click the "Build DMG" button to generate the file

## Project Structure

```
DMGEditor/
├── DMGEditor/
│   ├── DMGEditorApp.swift          # App entry point
│   ├── DMGEditorView.swift         # Main UI view
│   ├── DMGEditorViewModel.swift    # View model
│   ├── DMGSettingsPanel.swift      # Settings panel
│   ├── DMGItemEditPanel.swift      # Item editing panel
│   ├── DMGCanvasView.swift         # Canvas view
│   ├── DMGCanvasNSView.swift       # NSView canvas implementation
│   ├── DMGFileDropView.swift       # File drop zone view
│   ├── DMGItemView.swift           # Item view component
│   ├── model/
│   │   ├── DMGConfig.swift         # DMG configuration model
│   │   ├── DMGItemModel.swift      # Item data model
│   │   └── DMGItemType.swift       # Item type definitions
│   └── service/
│       ├── ConfigService.swift     # Configuration save/load service
│       └── CreateDMGService.swift  # DMG build service
├── DMGEditorTests/                  # Unit tests
├── DMGEditorUITests/               # UI tests
├── Resources/                       # Resource files
│   ├── create-dmg                  # DMG build script
│   ├── template.applescript1       # AppleScript template
│   └── eula-resources-template.xml # EULA template
├── INTEGRATION_NOTES.md            # Integration notes
├── CREATE_DMG_GUIDE.md             # Feature development guide (Chinese)
└── README_CN.md                     # Chinese version of README
```

## Tech Stack

- **Language**: Swift 5.x
- **Framework**: SwiftUI, AppKit
- **Architecture**: MVVM (Model-View-ViewModel)
- **Build Tool**: Xcode
- **Dependency**: create-dmg script

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

[MIT License](LICENSE)

## Related Links

- [create-dmg Official Repository](https://github.com/create-dmg/create-dmg)

---

Made with ❤️ by PurpleAxis-ZK
