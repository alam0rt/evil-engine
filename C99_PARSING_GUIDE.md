# C99 BLB Parsing Library Guide

## Overview

All BLB format parsing logic is implemented in the C99 library (`src/blb/`, `src/level/`). The GDScript `blb_reader.gd` is a pure GDScript reference implementation that mirrors the C99 code.

## Architecture

```
┌────────────────────────────────────────────┐
│ C99 Library (src/)                         │
│ - BLB format parsing                       │
│ - Binary structure reading                 │
│ - Tile/sprite/palette extraction           │
│ - NO game-specific logic                   │
└──────────────────┬─────────────────────────┘
                   │
                   ├─────────────┐
                   ↓             ↓
        ┌──────────────┐  ┌─────────────────┐
        │ GDExtension  │  │ GDScript (ref)  │
        │ (gdextension)│  │ (blb_reader.gd) │
        │              │  │                 │
        │ (TODO: Bind │  │ Works now but   │
        │  C99 funcs)  │  │ duplicates C99  │
        └──────┬───────┘  └────────┬────────┘
               │                   │
               └─────────┬─────────┘
                         ↓
        ┌────────────────────────────────┐
        │ Godot Scene Builder            │
        │ (blb_stage_scene_builder.gd)   │
        │ - Uses parsing functions       │
        │ - Builds Godot scenes          │
        └────────────────┬───────────────┘
                         │
                         ↓
        ┌────────────────────────────────┐
        │ Game Data (game_data/)         │
        │ - Entity type → Sprite ID      │
        │ - Entity names/colors          │
        │ - GAME-SPECIFIC (not BLB)      │
        └────────────────────────────────┘
```

## C99 Library Functions

### BLB File Operations
```c
// Opening/closing
int BLB_Open(const char* path, BLBFile* blb);
void BLB_Close(BLBFile* blb);

// Header access
u8 BLB_GetLevelCount(const BLBFile* blb);
const char* BLB_GetLevelName(const BLBFile* blb, u8 level_index);
const char* BLB_GetLevelID(const BLBFile* blb, u8 level_index);
u16 BLB_GetStageCount(const BLBFile* blb, u8 level_index);

// Sector access
u16 BLB_GetPrimarySectorOffset(const BLBFile* blb, u8 level_index);
u16 BLB_GetSecondarySectorOffset(const BLBFile* blb, u8 level_index, u8 stage);
u16 BLB_GetTertiarySectorOffset(const BLBFile* blb, u8 level_index, u8 stage);
const u8* BLB_GetSectorData(const BLBFile* blb, u16 sector_offset);

// Asset finding
const u8* BLB_FindAsset(const BLBFile* blb, const u8* segment_start, 
                        u32 asset_id, u32* out_size);
```

### Palette Parsing
```c
// Parse palette container (Asset 400)
int BLB_ParsePaletteContainer(const u8* palette_data, u32* out_count);
const u16* BLB_GetPaletteFromContainer(const u8* palette_data, u8 palette_index, u32* out_size);

// Color conversion
u32 BLB_PSXColorToRGBA(u16 psx_color);  // 15-bit PSX → 32-bit RGBA
```

### Sprite Parsing
```c
// Parse sprite container (Asset 600)
int BLB_ParseSpriteContainer(const u8* sprite_data, u32* out_count);
const u8* BLB_GetSpriteFromContainer(const u8* sprite_data, u32 sprite_index,
                                     u32* out_sprite_id, u32* out_size);

// Sprite header/animations
int BLB_ParseSpriteHeader(const u8* sprite_data, SpriteHeader* out_header);
int BLB_GetSpriteAnimation(const u8* sprite_data, u32 anim_index, SpriteAnim* out_anim);
int BLB_GetSpriteFrameMetadata(const u8* sprite_data, u16 frame_meta_offset,
                               u32 frame_index, SpriteFrame* out_frame);
const u16* BLB_GetSpritePalette(const u8* sprite_data, u32 palette_offset);
```

### Level Operations
```c
// Load level data
int Level_Load(LevelContext* ctx, const BLBFile* blb, u8 level_index, u8 stage_index);
void Level_Unload(LevelContext* ctx);

// Tile access
const u8* Level_GetTilePixels(const LevelContext* ctx, u16 tile_index, int* out_is_8x8);
const u16* Level_GetTilePalette(const LevelContext* ctx, u16 tile_index);
u8 Level_GetTileFlags(const LevelContext* ctx, u16 tile_index);

// Layer access
const LayerEntry* Level_GetLayer(const LevelContext* ctx, u32 layer_index);
const u16* Level_GetLayerTilemap(const LevelContext* ctx, u32 layer_index);

// Entity access
const EntityDef* entities;  // Directly accessible from LevelContext
u32 entity_count;
```

## Public API (evil_engine.h)

The `evil_engine.h` header provides a clean public API that wraps all internal functions:

```c
#include "evil_engine.h"

// Open BLB
BLBFile* blb;
EvilEngine_OpenBLB("GAME.BLB", &blb);

// Load level
LevelContext* level;
EvilEngine_LoadLevel(blb, 0, 0, &level);

// Get parsed data
const TileHeader* header = EvilEngine_GetTileHeader(level);
const LayerEntry* layer = EvilEngine_GetLayer(level, 0);
const EntityDef* entities = EvilEngine_GetEntities(level, &count);

// Get palettes
int pal_count = EvilEngine_GetPaletteCount(level);
const u16* palette = EvilEngine_GetPalette(level, 0, &size);

// Get sprites (from raw asset)
const u8* sprite_container = EvilEngine_GetAssetData(blb, 0, 0, 2, ASSET_SPRITE_CONTAINER, &size);
int sprite_count;
EvilEngine_GetSpriteCount(sprite_container, &sprite_count);

// Cleanup
EvilEngine_UnloadLevel(level);
EvilEngine_CloseBLB(blb);
```

## GDScript Usage (Current)

Currently, GDScript uses `blb_reader.gd` which reimplements all C99 logic:

```gdscript
var blb := BLBReader.new()
blb.open("res://GAME.BLB")

var stage_data := blb.load_stage(0, 0)
var tile_header := stage_data["tile_header"]
var palettes := stage_data["palettes"]
var sprites := stage_data["sprites"]
```

## Future: GDExtension Usage

Once GDExtension bindings are complete, GDScript will call C99 directly:

```gdscript
var blb := BLBArchive.new()
blb.open("res://GAME.BLB")
blb.load_level(0, 0)

var tile_header := blb.get_tile_header()  # Returns Dictionary from C
var palette_count := blb.get_palette_count()
var palette := blb.get_palette(0)  # PackedColorArray from C
var sprite_count := blb.get_sprite_count(2)  # From tertiary
```

## Function Mapping

| GDScript (blb_reader.gd) | C99 Library | Status |
|--------------------------|-------------|--------|
| `open()` | `BLB_Open()` | ✅ Implemented |
| `get_level_count()` | `BLB_GetLevelCount()` | ✅ Implemented |
| `get_level_name()` | `BLB_GetLevelName()` | ✅ Implemented |
| `get_sector_data()` | `BLB_GetSectorData()` | ✅ Implemented |
| `find_asset()` | `BLB_FindAsset()` | ✅ Implemented |
| `_parse_tile_header()` | `TileHeader` struct access | ✅ Implemented |
| `_parse_layer_entries()` | `LayerEntry` struct access | ✅ Implemented |
| `_parse_entities()` | `EntityDef` struct access | ✅ Implemented |
| `_parse_palette_container()` | `BLB_ParsePaletteContainer()` | ✅ Implemented |
| `_parse_sprite_container()` | `BLB_ParseSpriteContainer()` | ✅ Implemented |
| `_parse_sprite()` | `BLB_ParseSpriteHeader()` | ✅ Implemented |
| `_parse_frame_metadata()` | `BLB_GetSpriteFrameMetadata()` | ✅ Implemented |
| `_psx_to_color()` | `BLB_PSXColorToRGBA()` | ✅ Implemented |
| `get_tile_is_8x8()` | `IsTile8x8()` (render.h) | ✅ Implemented |
| `decode_sprite_frame()` | Custom (RLE decoder) | ⚠️ In GDScript |

## What Stays in GDScript

### 1. RLE Decoding (decode_sprite_frame)
Currently in GDScript, could be moved to C99 for performance. The RLE algorithm is part of BLB format, not game-specific.

### 2. Image Building (Godot-specific)
- `Image.create()`, `Image.set_pixel()` - Godot API calls
- TileSet creation - Godot resource system
- Scene building - Godot scene tree

### 3. Game Data (game_data/)
- Entity type names/descriptions
- Entity → Sprite ID mappings
- Visual colors for editor
- Level folder names

## Benefits of C99 Parsing

✅ **Single source of truth** - One implementation of BLB format
✅ **Reusable** - CLI tools, other engines can use same library
✅ **Performance** - C99 is faster than GDScript for binary parsing
✅ **Maintainability** - Fix once, benefits all users
✅ **Type safety** - C structs ensure correct memory layout
✅ **Verifiable** - Can compare directly with original game code

## Next Steps

To complete the GDExtension bindings:

1. Implement GDExtension class registration in `gdextension/blb_archive.c`
2. Add method bindings for all C99 functions
3. Implement type conversion helpers (C structs → GDScript Dictionaries)
4. Update `blb_stage_scene_builder.gd` to use GDExtension instead of blb_reader
5. Keep `blb_reader.gd` as reference/fallback

See `gdextension/blb_archive.c` for current GDExtension stub implementation.

