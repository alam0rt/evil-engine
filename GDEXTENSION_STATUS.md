# GDExtension Implementation Status

## Overview

The GDExtension provides C-speed BLB parsing by exposing the C99 library functions to GDScript.

## Current Status

### ✅ Infrastructure Complete

The GDExtension has a well-structured foundation:

#### Custom Helpers
- **api.h/api.c** - Caches GDExtension function pointers for efficient access
- **class_binding.h/class_binding.c** - Simplifies class and method registration
- **gd_helpers.h/gd_helpers.c** - Type conversion utilities

#### Class Registration
- **BLBArchive** class extends RefCounted
- Proper constructor/destructor with instance data management
- Method binding infrastructure with both `call` and `ptrcall` implementations

### ✅ Implemented Methods

The BLBArchive class exposes these C99 functions to GDScript:

```gdscript
var blb := BLBArchive.new()

# File operations
blb.open(path: String) -> bool
blb.close() -> void

# Level info
blb.get_level_count() -> int
blb.get_level_id(index: int) -> String
blb.get_level_name(index: int) -> String
blb.get_stage_count(level_index: int) -> int

# Sector access
blb.get_primary_sector(level_index: int) -> int
blb.get_tertiary_sector(level_index: int, stage_index: int) -> int

# Raw asset access
blb.get_asset_data(level_index: int, stage_index: int, segment_type: int, asset_id: int) -> PackedByteArray

# Utility
blb.psx_color_to_rgba(psx_color: int) -> int
```

### C99 Functions Available

All parsing functions are now in the C99 library and can be exposed:

#### BLB File Operations
- ✅ `BLB_Open()`, `BLB_Close()`
- ✅ `BLB_GetLevelCount()`, `BLB_GetLevelName()`, `BLB_GetLevelID()`
- ✅ `BLB_GetSectorData()`, `BLB_FindAsset()`

#### Palette Operations
- ✅ `BLB_ParsePaletteContainer()` - Get palette count
- ✅ `BLB_GetPaletteFromContainer()` - Get specific palette
- ✅ `BLB_PSXColorToRGBA()` - Color conversion

#### Sprite Operations
- ✅ `BLB_ParseSpriteContainer()` - Get sprite count
- ✅ `BLB_GetSpriteFromContainer()` - Get specific sprite
- ✅ `BLB_ParseSpriteHeader()` - Parse sprite header
- ✅ `BLB_GetSpriteAnimation()` - Get animation data
- ✅ `BLB_GetSpriteFrameMetadata()` - Get frame metadata
- ✅ `BLB_GetSpritePalette()` - Get sprite's embedded palette

#### Level Operations
- ✅ `Level_Load()`, `Level_Unload()`
- ✅ `Level_GetTilePixels()` - With 8x8 detection
- ✅ `Level_GetTilePalette()`, `Level_GetTileFlags()`
- ✅ `Level_GetLayer()`, `Level_GetLayerTilemap()`

### ⚠️ Limitations

#### PackedByteArray Data Transfer
The `get_asset_data()` method currently returns an empty PackedByteArray. To properly return data:

**Need to implement:**
```c
void variant_new_packed_byte_array_from_data(GdVariant* r_dest, const uint8_t* p_data, int p_size) {
    // 1. Create empty PackedByteArray
    // 2. Resize to p_size
    // 3. Copy p_data into array
    // Requires: packed_byte_array_operator_index or similar API
}
```

**Workaround**: GDScript can use `blb_reader.gd` for now, which works perfectly.

### 🎯 Usage Comparison

#### Current (GDScript blb_reader.gd)
```gdscript
var blb := BLBReader.new()
blb.open("res://GAME.BLB")
var stage_data := blb.load_stage(0, 0)
# Works perfectly, all features available
```

#### Future (GDExtension BLBArchive)
```gdscript
var blb := BLBArchive.new()
blb.open("res://GAME.BLB")

# Get level info
var count = blb.get_level_count()
var name = blb.get_level_name(0)

# Get raw asset data (when PackedByteArray transfer works)
var tile_header_bytes = blb.get_asset_data(0, 0, 1, 100)  # Secondary, Asset 100

# Convert PSX colors
var rgba = blb.psx_color_to_rgba(0x7FFF)  # White
```

## Build Integration

### Files Included in Build

`meson.build` includes:
```meson
gdext_files = files(
  'gdextension/entry.c',
  'gdextension/engine_node.c',
  'gdextension/blb_archive.c',
  'gdextension/gd_helpers.c',
  'gdextension/api.c',              # API wrapper
  'gdextension/class_binding.c',    # Class registration helpers
)
```

### Dependencies

The GDExtension links with:
- C99 library (`lib_files`) - BLB/Level parsing
- Game logic (`game_files`) - Game state management

## Recommendation

### Current State: Use blb_reader.gd ✅

The pure GDScript implementation is:
- ✅ Complete and functional
- ✅ Well-documented with C99 references
- ✅ Handles all BLB parsing correctly
- ✅ Supports 8x8 tiles properly
- ✅ Enables full round-trip editing

### Future: Complete GDExtension

When performance becomes critical:
1. Implement PackedByteArray data transfer
2. Add more helper methods (parse_tile_header, parse_layers, etc.)
3. Benchmark GDExtension vs. GDScript
4. Update scene builders to use GDExtension

## Testing GDExtension

To test the current GDExtension implementation:

```gdscript
# In a Godot script
func test_blb_archive():
    var blb := BLBArchive.new()
    
    if blb.open("res://assets/GAME.BLB"):
        print("Level count: ", blb.get_level_count())
        print("Level 0 name: ", blb.get_level_name(0))
        print("Level 0 ID: ", blb.get_level_id(0))
        print("Stage count: ", blb.get_stage_count(0))
        
        # Test color conversion
        var white_psx = 0x7FFF
        var rgba = blb.psx_color_to_rgba(white_psx)
        print("PSX white to RGBA: 0x%08x" % rgba)
        
        blb.close()
    else:
        print("Failed to open BLB")
```

## Summary

✅ **C99 Library**: Complete with all parsing functions
✅ **GDExtension Infrastructure**: Well-structured and extensible
✅ **Basic Methods**: File operations and metadata access working
⚠️ **Data Transfer**: PackedByteArray needs proper implementation
✅ **GDScript Fallback**: blb_reader.gd provides full functionality

The architecture is solid and ready for optimization when needed!

