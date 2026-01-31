# create-dmg Integration Notes

## Overview
DMGEditor now uses the `create-dmg` script from https://github.com/create-dmg/create-dmg.git to generate DMG files with professional layouts and positioning.

## Integration Details

### File Structure
```
DMGEditor/
├── Resources/
│   └── scripts/
│       ├── create-dmg          # Main script (executable)
│       ├── README.md           # Original create-dmg documentation
│       └── [other create-dmg files]
└── DMGEditor/
    └── CreateDMGService.swift  # Integrated service
```

### CreateDMGService Implementation
The `CreateDMGService.build()` method now:

1. **Locates create-dmg script** from multiple sources:
   - Bundle Resources/scripts/
   - App bundle Contents/Resources/scripts/
   - Project Resources/scripts/ (development)
   - System PATH (via `which create-dmg`)

2. **Builds command arguments** based on DMGConfig and items:
   ```swift
   --volname {volume_name}
   --window-size {width} {height}
   --icon-size {size}
   --background {background_image_path}
   [--icon {file_name} {x} {y}] (for .app items)
   [--app-drop-link {x} {y}] (for applications folder)
   [--add-file {name} {path} {x} {y}] (for file items)
   --output.dmg {source_folder}
   ```

3. **Processes output** and logs results in real-time

### How Items Map to Parameters

| Item Type | create-dmg Parameter | Purpose |
|-----------|-------------------|---------|
| `.app` | `--icon {name} {x} {y}` | Main application icon at position |
| `.applications` | `--app-drop-link {x} {y}` | Applications folder shortcut |
| `.file` | `--add-file {name} {path} {x} {y}` | Additional files/folders |

### Example Usage Flow

1. User configures DMG in the UI:
   - Sets volume name, window size, icon size
   - Selects background image
   - Positions items (app, applications folder, additional files)

2. User clicks "Build DMG"

3. CreateDMGService:
   - Validates app path exists
   - Locates create-dmg script
   - Builds command with all parameters
   - Executes: `./create-dmg [options] MyApp.dmg /path/to/app`

4. DMG file created with all specified items at their positions

## Building and Distribution

### Development
When running from Xcode or during development, the script is loaded from:
```
/Users/xtxk/Documents/DMGEditor/Resources/scripts/create-dmg
```

### Distribution
When distributing the app, ensure the build system copies create-dmg to:
```
MyApp.app/Contents/Resources/scripts/create-dmg
```

This can be done by adding a Copy Files build phase or similar mechanism.

## Troubleshooting

### Script Not Found
If you see "create-dmg script not found":
1. Verify script exists and has execute permissions:
   ```bash
   ls -la Resources/scripts/create-dmg
   chmod +x Resources/scripts/create-dmg
   ```
2. Check that it's included in the app bundle when deployed
3. Ensure it's in the system PATH if using system-installed version

### Build Fails with Errors
- Check that all file paths in items exist
- Verify background image is a valid image file
- Ensure output folder is writable
- Check DMGConfig values are reasonable

## References
- Original Repository: https://github.com/create-dmg/create-dmg
- create-dmg Documentation: See Resources/scripts/README.md
