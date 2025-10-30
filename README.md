# Corona Material Color Adjuster

⚠️ **BETA VERSION - Under Testing and Development**

A MAXScript tool for adjusting color brightness in Corona Physical Materials and adding tonal correction to textured materials.

## ⚠️ Important Warning

**This script is in testing phase. Use with caution!**

- **Always save your file before running this script**
- Test on a backup copy first
- Report any bugs or unexpected behavior

## Overview

This script helps control excessive brightness in Corona materials by:
- Limiting RGB values in solid color materials
- Adding CoronaColorCorrect nodes with custom curves to textured materials

## Features

### Solid Color Processing
- Automatically detects materials with baseColor values exceeding threshold
- Proportionally scales RGB values while preserving hue and saturation
- Works with both direct colors and CoronaColor nodes

### Texture Processing
- Identifies materials with bitmap textures
- Inserts CoronaColorCorrect node with custom tonal curve
- Curve points: (0, 0), (0.503, 0.503), (1, 0.718)

## Installation & Usage

1. Download the script file
2. Save it with `.ms` extension (e.g., `corona_color_adjuster.ms`)
3. **Save your 3ds Max scene before proceeding**
4. Drag and drop the file into the 3ds Max viewport
5. Set desired Value limit (default: 220)
6. Select materials to process from the lists
7. Click "Process Materials"

## Technical Details

### Color Value Conversion
The script uses internal conversion: UI value 220 = code value 184
- Formula: `codeValue = uiValue × (184/220)`

### Material Detection
- Scans all CoronaPhysicalMtl in scene
- Filters materials with Value > threshold
- Separates solid colors from textured materials

## Requirements

- 3ds Max 2020 or higher
- Corona Renderer 7.0 or higher

## Known Issues

- Beta stage: may contain bugs
- Test on backup files first

## Credits

The color adjustment method used in this script was originally shared by Vjeko from RenderRam.  
For more information and support, visit: https://www.patreon.com/RenderRam

## Contributing

This tool is in active development. Bug reports and suggestions welcome.


---

**Status**: Beta Testing  
**Version**: 1.0  
**Last Updated**: 2025
