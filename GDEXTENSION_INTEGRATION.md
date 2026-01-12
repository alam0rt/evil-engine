# GDExtension Integration Guide

## Current Architecture (Optimal)

The current system is already well-architected! Here's why:

### Data Flow

```
BLB File (bytes)
    ↓
BLBReader.load_stage()  ← Uses C99-equivalent parsing
    ↓
Dictionary {           ← Pre-parsed data structure
  tile_header: {...},
  palettes: [...],
  layers: [...],
  entities: [...],
  sprites: [...],
}
    ↓
BLBStageSceneBuilder.build_scene(stage_data)
    ↓
PackedScene (Godot scene file)
```

### Why This Works Well

**1. Parsing is done once** - `BLBReader.load_stage()` parses everything upfront
**2. Scene builder is simple** - Just builds Godot nodes from dictionaries
**3. No repeated parsing** - Data is passed as structured dictionaries
**4. Image manipulation in GDScript** - Godot's Image API is already in GDScript

### Where GDExtension Helps

The GDExtension BLBArchive is useful for:

**✅ Direct C99 access** when you need specific parsing:
```gdscript
var blb := BLBArchive.new()
blb.open("res://GAME.BLB")
var level_count = blb.get_level_count()
var level_name = blb.get_level_name(0)
blb.close()
```

**✅ Performance hotspots**:
- Decoding many sprites in C instead of GDScript
- Parsing large tilemaps
- Real-time BLB reading

**✅ CLI tool integration**:
- Using same BLBArchive API in editor scripts
- Batch processing BLB files

## Recommended Usage

### For Scene Building (Current - Already Optimal)

**Use BLBReader** - It works perfectly:

```gdscript
# In blb_import_plugin.gd or blb_browser_dock.gd
var blb := BLBReader.new()
blb.open(source_file)

var stage_data := blb.load_stage(level_index, stage_index)

var builder := BLBStageSceneBuilder.new()
var scene := builder.build_scene(stage_data, blb)
```

**Why this is optimal:**
- ✅ `load_stage()` does all parsing once
- ✅ Returns structured Dictionary
- ✅ Scene builder just builds nodes
- ✅ Clean separation
- ✅ No performance issues

### For Direct BLB Queries (Use GDExtension)

**Use BLBArchive** when you need specific info:

```gdscript
# Quick level info without full parsing
var blb := BLBArchive.new()
if blb.open("res://GAME.BLB"):
    for i in range(blb.get_level_count()):
        print("%d: %s (%s)" % [i, blb.get_level_name(i), blb.get_level_id(i)])
    blb.close()
```

### For Performance Optimization (Future)

**Replace hotspots** with C99 calls:

```gdscript
# Example: Decode sprite in C instead of GDScript
var blb := BLBArchive.new()
blb.open("res://GAME.BLB")

# Get sprite container from tertiary
var sprite_data = blb.get_asset_data(level_idx, stage_idx, 2, 600)

# Parse in C (future: add decode_sprite_frame to C99)
# For now: use BLBReader.decode_sprite_frame()
```

## Migration Strategy (If Needed)

### Phase 1: Keep Current System ✅

The current BLBReader-based system is production-ready:
- ✅ Fully functional
- ✅ Well-documented
- ✅ All features working
- ✅ Round-trip editing complete

### Phase 2: Add GDExtension for Specific Cases (Optional)

Add GDExtension usage only where it provides clear benefit:

**Example: Level list**:
```gdscript
# OLD (works fine):
var blb := BLBReader.new()
blb.open(path)
var count = blb.get_level_count()

# NEW (slightly faster):
var blb := BLBArchive.new()
blb.open(path)
var count = blb.get_level_count()
```

**Example: Sprite decoding** (future):
```gdscript
# Add to C99 library:
int EvilEngine_DecodeRLESprite(const u8* sprite_data, int anim_idx, int frame_idx, u8* out_rgba);

# Then call from GDExtension:
var image_bytes = blb.decode_sprite_frame(sprite_id, anim_idx, frame_idx)
var image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, image_bytes)
```

### Phase 3: Benchmark and Optimize (If Needed)

Only if performance becomes an issue:
1. Profile the import process
2. Identify bottlenecks
3. Replace specific hotspots with GDExtension calls
4. Keep GDScript for everything else

## Current Method Availability

### BLBArchive (GDExtension) - Available Now

```gdscript
var blb := BLBArchive.new()

blb.open(path: String) -> bool
blb.close() -> void
blb.get_level_count() -> int
blb.get_level_id(index: int) -> String
blb.get_level_name(index: int) -> String
blb.get_stage_count(level_index: int) -> int
blb.get_primary_sector(level_index: int) -> int
blb.get_tertiary_sector(level_index: int, stage_index: int) -> int
blb.get_asset_data(level_index: int, stage_index: int, segment_type: int, asset_id: int) -> PackedByteArray
blb.psx_color_to_rgba(psx_color: int) -> int
```

### BLBReader (GDScript) - Available Now

```gdscript
var blb := BLBReader.new()

blb.open(path: String) -> bool
blb.get_level_count() -> int
blb.get_level_name(level_index: int) -> String
blb.get_level_id(level_index: int) -> String
blb.get_stage_count(level_index: int) -> int
blb.get_sector_data(sector_offset: int) -> PackedByteArray
blb.find_asset(segment_data: PackedByteArray, asset_id: int) -> Dictionary
blb.load_stage(level_index: int, stage_index: int) -> Dictionary  # ← KEY METHOD
blb.load_sprites(level_index: int, stage_index: int) -> Array
blb.load_primary_sprites(level_index: int) -> Array
blb.decode_sprite_frame(sprite: Dictionary, anim_idx: int, frame_idx: int) -> Image
```

## Recommendation

### ✅ Keep Using BLBReader for Scene Building

The current system is optimal because:

1. **`load_stage()` is a high-level helper** - Returns everything in one Dictionary
2. **Scene builder is clean** - Just builds nodes from data
3. **No performance issues** - Parsing happens once, building is fast
4. **Image manipulation needs Godot API** - Already in GDScript

### ✅ Use BLBArchive for Utilities

Add GDExtension calls where appropriate:

**Browser dock level list**:
```gdscript
# blb_browser_dock.gd
var blb := BLBArchive.new()  # ← Use GDExtension for metadata
if blb.open(path):
    for i in range(blb.get_level_count()):
        # ... populate tree ...
```

**Export validation**:
```gdscript
# Check if BLB is valid before full parse
var blb := BLBArchive.new()
if blb.open(path):
    if blb.get_level_count() > 0:
        # Valid BLB
```

## Conclusion

**The current BLBReader-based system should remain the primary implementation** because:
- ✅ It's complete and functional
- ✅ It's well-documented with C99 references
- ✅ Performance is already good
- ✅ The architecture is clean

**The BLBArchive GDExtension is available for**:
- ✅ Specific utility functions
- ✅ Future performance optimization
- ✅ Consistency with C99 library

No migration is needed - both can coexist, each serving its purpose! 🎉

