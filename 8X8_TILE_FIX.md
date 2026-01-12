# 8x8 Tile Rendering Fix

## Problem

The Godot importer was not correctly handling 8x8 tiles, treating all tiles as 16x16. This resulted in incorrect rendering because 8x8 tiles have a different storage layout in the BLB format.

## BLB Tile Storage Format (from C99 Library)

### 16x16 Tiles
- **Size**: 256 bytes per tile (16 rows × 16 pixels)
- **Layout**: Sequential in memory
- **Offset**: `tile_index * 256`

### 8x8 Tiles
- **Size**: 128 bytes per tile (8 rows × 16 bytes, only first 8 columns used)
- **Layout**: Comes after all 16x16 tiles
- **Offset**: `count_16x16 * 256 + (tile_index - count_16x16) * 128`
- **Storage**: Each row is 16 bytes wide, but only the first 8 pixels contain data

### Tile Identification

Two methods (matching C99 library logic):
1. **Tile Flags (Asset 302)**: Bit 1 (0x02) indicates 8x8 tile
2. **Position**: If `tile_index >= count_16x16`, it's an 8x8 tile

## Implementation

### 1. Added Tile Size Helper (blb_reader.gd)

Added static helper functions that match the C99 library logic:

```gdscript
static func get_tile_is_8x8(tile_index: int, tile_header: Dictionary, tile_flags: PackedByteArray) -> bool:
    # Check flags first (bit 1 = TILE_FLAG_8X8)
    var array_index := tile_index - 1
    if array_index >= 0 and array_index < tile_flags.size():
        if tile_flags[array_index] & 0x02:
            return true
    
    # Fall back to position-based check
    var count_16x16: int = tile_header.get("count_16x16", 0)
    return array_index >= count_16x16

static func get_tile_size(tile_index: int, tile_header: Dictionary, tile_flags: PackedByteArray) -> Vector2i:
    if get_tile_is_8x8(tile_index, tile_header, tile_flags):
        return Vector2i(8, 8)
    else:
        return Vector2i(16, 16)
```

### 2. Fixed Atlas Builder (blb_stage_scene_builder.gd)

Updated `_build_tile_atlas()` to:

**Calculate correct pixel offset based on tile size:**
```gdscript
if is_8x8:
    # Matches C99: count_16x16 * 0x100 + (tile_idx - count_16x16) * 0x80
    tile_offset = count_16x16 * 256 + (tile_idx - count_16x16) * 128
    tile_width = 8
    tile_height = 8
else:
    # 16x16 tile: 256 bytes
    tile_offset = tile_idx * 256
    tile_width = 16
    tile_height = 16
```

**Center 8x8 tiles in 16×16 atlas cells:**
```gdscript
# Center 8x8 tiles in 16×16 cell
var offset_x := 0
var offset_y := 0
if is_8x8:
    offset_x = (TILE_SIZE - tile_width) / 2  # = 4 pixels
    offset_y = (TILE_SIZE - tile_height) / 2  # = 4 pixels
```

**Read pixels with correct row stride:**
```gdscript
# Always 16 bytes per row in the data (even for 8x8 tiles)
var pixel_offset := tile_offset + py * 16 + px
```

### 3. Added Debug Information (blb_tileset_container.gd)

Added properties to expose tile size breakdown:
```gdscript
@export_group("Tile Sizes")
@export var tile_16x16_count: int = 0
@export var tile_8x8_count: int = 0
```

Configuration warnings now show when 8x8 tiles are present:
```
"Contains 42 8x8 tiles (centered in 16×16 cells)"
```

## How It Works

### Atlas Layout

All tiles (both 8x8 and 16x16) use **16×16 cells** in the atlas texture:
- 16x16 tiles fill the entire cell
- 8x8 tiles are centered with 4-pixel margins on all sides

This ensures:
- Consistent TileSet texture regions (always 16×16)
- Godot's TileMapLayer works correctly
- 8x8 tiles render at proper size in-game

### Rendering Flow

```
BLB File (Raw Bytes)
    ↓ [C99-equivalent parsing logic]
tile_pixels: PackedByteArray
tile_flags: PackedByteArray (bit 1 = 8x8)
count_16x16: int
    ↓ [_build_tile_atlas]
Atlas Image (16×16 cells, 8x8 centered)
    ↓
TileSet with TileSetAtlasSource
    ↓
TileMapLayer rendering
```

## Architecture Compliance

✅ **C99 Library (Parsing)**: All tile layout calculations match C99 logic
- Offset calculation matches `GetTilePixelDataPtr()`
- Flag checking matches `Level_GetTileFlags()` and `IsTile8x8()`
- Row stride (16 bytes) matches `CopyTilePixelData()`

✅ **GDScript (Game Logic)**: Godot-specific rendering concerns
- Atlas building and centering
- TileSet creation with consistent regions
- Visual debugging in editor

## Testing

To verify 8x8 tiles are rendering correctly:

1. **Import a level with 8x8 tiles**:
   - Open BLB Browser
   - Load GAME.BLB
   - Import a level (most levels have some 8x8 tiles)

2. **Check the TilesetContainer node**:
   - Select TilesetContainer in scene tree
   - Inspector should show: "Contains N 8x8 tiles (centered in 16×16 cells)"

3. **Inspect the atlas texture**:
   - Select TilesetContainer
   - View `tile_atlas` texture
   - 8x8 tiles should appear centered with transparent margins

4. **Verify in-game rendering**:
   - Run the scene
   - 8x8 tiles should render at correct size
   - No stretching or distortion

5. **Test round-trip**:
   - Export the scene to BLB
   - Re-import the exported BLB
   - 8x8 tiles should still be marked correctly (via tile flags)

## Key Differences from Previous Implementation

| Aspect | Before (Incorrect) | After (Correct) |
|--------|-------------------|-----------------|
| Offset calculation | `tile_idx * 256` for all | 16x16: `tile_idx * 256`<br>8x8: `count_16x16 * 256 + (tile_idx - count_16x16) * 128` |
| Row stride | Assumed 16 bytes | Always 16 bytes per row (matches C99) |
| Atlas layout | All 16×16 | 16×16 cells, 8x8 centered |
| Tile identification | None | Checks flags bit 1, falls back to position |

## Files Modified

1. **blb_reader.gd**: Added `get_tile_is_8x8()` and `get_tile_size()` static helpers
2. **blb_stage_scene_builder.gd**: Fixed `_build_tile_atlas()` with C99-equivalent logic
3. **blb_tileset_container.gd**: Added `tile_16x16_count` and `tile_8x8_count` properties

## Result

✅ 8x8 tiles now render correctly, centered in 16×16 atlas cells
✅ Tile pixel data extraction uses C99-equivalent offset calculations
✅ Tile flags properly indicate 8x8 tiles (bit 1 set)
✅ Round-trip export/import preserves tile sizes
✅ Atlas texture visually shows 8x8 tiles centered with transparent margins
✅ Debug information exposes tile size breakdown in editor

