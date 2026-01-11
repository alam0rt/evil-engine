# Project: Evil Engine - Skullmonkeys PSX Viewer/Editor

A Godot 4.5 GDExtension (C99) for viewing and editing Skullmonkeys (SLES-01090) assets.

## Project Goals

1. **Authentic C99 Core**: All BLB parsing, level loading, and rendering code should match the original PSX decompilation as closely as possible. This code will eventually be used to produce a matching decompilation.

2. **Thin Godot Wrapper**: A minimal GDExtension layer that exposes the authentic C code to Godot for building level viewers, asset browsers, and editing tools.

## Architecture

```
evil-engine/
├── src/                    # Authentic C99 engine code
│   ├── psx/               # PSX type definitions (u8, u16, s32, etc.)
│   ├── blb/               # BLB file format parsing
│   ├── level/             # Level loading and data structures
│   ├── render/            # Tile/sprite rendering accessors
│   └── game.c             # Game loop (optional, for testing)
├── gdextension/           # Godot wrapper (thin layer only)
├── include/               # Shared headers
└── build/                 # Meson build output
```

## Build System

- **Meson + Ninja**: `meson setup build && ninja -C build`
- **Test executables**: Compile with `gcc -std=c99 -O2 -Isrc -Iinclude`

## Coding Standards

### C99 Authentic Code (src/)

- Match original function names from Ghidra decompilation
- Use PSX types: `u8`, `u16`, `u32`, `s8`, `s16`, `s32`
- Document Ghidra addresses in comments: `/* Based on @ 0x8007b4f8 */`
- Follow original memory layouts and access patterns
- No C++ or Godot dependencies in this layer

### GDExtension Wrapper (gdextension/)

- Minimal translation layer only
- Convert between Godot types and C99 types
- Expose methods like `load_blb()`, `load_level()`, `render_tile_to_image()`

## Key Data Structures

### BLB File Format
- Container format for all game assets
- 26 levels, each with up to 6 stages
- Sub-TOC pattern: 12-byte entries with offset at +8

### Level Context
- Mirrors original `LevelDataContext` structure
- Stores pointers to: tile header, tile pixels, palettes, tilemaps, entities

### Tiles
- 16x16 or 8x8 pixels, 8bpp indexed
- Palette indices stored separately (1 byte per tile)
- Flags: semi-transparent (0x01), 8x8 size (0x02), skip (0x04)

### PSX Colors
- 15-bit BGR format: `0BBBBBGGGGGRRRRR`
- Convert to RGBA: `(r << 3) | (g << 11) | (b << 19) | alpha`

## Ghidra Integration

When decompiling new functions:

1. Use Ghidra MCP tools to get decompiled code
2. Note the function address in comments
3. Match variable names and control flow where possible
4. Document any deviations from original

### Key Addresses (PAL / SLES-01090)

| Function | Address | Purpose |
|----------|---------|---------|
| GetTileHeaderPtr | 0x8007b4b8 | Returns ctx + 0x04 |
| GetTotalTileCount | 0x8007b53c | Sum of 16x16 + 8x8 + extra |
| CopyTilePixelData | 0x8007b588 | Copy tile to buffer |
| GetTileSizeFlags | 0x8007b6bc | Returns ctx + 0x1C |
| GetTilemapDataPtr | 0x8007b6dc | Sub-TOC offset lookup |
| GetPaletteDataPtr | 0x8007b4f8 | Sub-TOC offset lookup |
| GetPaletteIndices | 0x8007b6b0 | Returns ctx + 0x18 |

## Testing

### Unit Tests
Create standalone test files that don't require Godot:
```bash
gcc -std=c99 -O2 -Isrc -Iinclude src/test_render.c src/blb/blb.c \
    src/level/level.c src/render/render.c -o build/test_render
./build/test_render /path/to/GAME.BLB
```

### Visual Verification
- Output PPM files for tile visualization
- Compare against known good renders

## Related Projects

- **btm** (`~/projects/btm`): Main decompilation project with Ghidra analysis
- **BLB hexpat** (`btm/scripts/blb.hexpat`): ImHex template (source of truth for format)
- **blb_viewer** (`btm/tools/blb_viewer`): Web-based viewer reference

## Workflow

1. Research function in Ghidra using MCP tools
2. Implement authentic C99 version in `src/`
3. Write standalone test to verify correctness
4. Add thin wrapper in `gdextension/` for Godot access
5. Document addresses and patterns in comments
