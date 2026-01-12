# BLB Round-trip Editing Test Guide

This guide describes how to test the complete round-trip workflow: importing a BLB file, editing it in Godot, and exporting it back to BLB format.

## Prerequisites

1. A BLB file (e.g., `GAME.BLB` from Skullmonkeys)
2. Godot 4.5+ with the BLB Importer plugin enabled
3. The evil-engine project open in Godot

## Test Workflow

### Step 1: Import a BLB Stage

1. Open Godot with the evil-engine project
2. Open the **BLB Browser** dock (usually at bottom-left)
3. Click **"Open BLB..."** and select your `GAME.BLB` file
4. The browser will show all levels in the archive
5. Double-click on any stage (e.g., "Level 1 → Stage 1")
6. Godot will:
   - Read the BLB data
   - Build a scene with all level properties
   - Save it to `res://scenes/blb_stages/`
   - Open it in the editor

### Step 2: Verify Imported Properties

Once the scene is open, inspect the various nodes:

#### BLBStageRoot Properties
- Select the root node
- In the Inspector, verify you can see:
  - **Tile Header**: `bg_color`, `fog_color`, `level_width`, `level_height`, `spawn_x`, `spawn_y`
  - **Tile counts**: `count_16x16`, `count_8x8`, `count_extra`
  - **Additional fields**: `vehicle_waypoints`, `level_flags`, `special_level_id`
  - **Raw Data**: `field_20`, `padding_22` (unknown/padding bytes)

#### BLBLayer Properties
- Expand **LayerContainer** and select any **Layer_X** node
- In the Inspector, verify you can see:
  - **Dimensions**: `map_width`, `map_height`
  - **Position**: `x_offset`, `y_offset`
  - **Parallax**: `scroll_x`, `scroll_y` (with range sliders)
  - **Rendering**: `render_param`, `render_mode_h`, `render_mode_v`
  - **Scroll flags**: `scroll_left_enable`, etc.
  - **Color Tints**: Array of 16 colors
  - **Raw Data**: `render_field_30`, etc. (unknown fields)

#### BLBEntity Properties
- Expand **EntityContainer** and select any **Entity_X** node
- In the Inspector, verify you can see:
  - **Bounds**: `x1`, `y1`, `x2`, `y2`
  - **Center**: `x_center`, `y_center`
  - **Type**: `entity_type`, `variant`, `layer`
  - **Raw Data**: `padding1`, `padding2`, `padding3`

### Step 3: Make Edits

Now make the following test edits:

#### Edit 1: Change Background Color
1. Select the root **BLBStageRoot** node
2. In Inspector, find **Tile Header → bg_color**
3. Change it from black `(0, 0, 0)` to blue `(0, 0, 255)` or any color you prefer
4. The background ColorRect should update immediately

#### Edit 2: Move an Entity
1. Select **EntityContainer → Entity_0** (or any entity)
2. In the 2D viewport, drag the entity to a new position
3. OR in Inspector, manually change `x_center` and `y_center`
4. Example: Move from `(100, 100)` to `(200, 150)`

#### Edit 3: Change Entity Dimensions
1. With the entity still selected
2. In Inspector, change the bounding box:
   - `x1`: 200 → 184
   - `y1`: 150 → 134
   - `x2`: 232 → 264
   - `y2`: 182 → 198
3. The orange placeholder should resize

#### Edit 4: Adjust Layer Parallax
1. Select **LayerContainer → Layer_0** (background layer)
2. In Inspector, find **Parallax → scroll_x**
3. Change from `0x10000` (1.0, camera speed) to `0x8000` (0.5, slower parallax)
4. This makes the layer scroll at half speed relative to camera

#### Edit 5: Modify Fog Color (Optional)
1. Select the root node again
2. In Inspector, find **Tile Header → fog_color**
3. Change to any color (e.g., light gray `(128, 128, 128)`)

### Step 4: Save the Scene

1. Press `Ctrl+S` (or `Cmd+S` on Mac) to save the scene
2. Godot saves all your changes to the `.tscn` file

### Step 5: Export to BLB

1. With the scene still open and saved
2. In the **BLB Browser** dock, click **"Export to BLB..."**
3. Choose a save location (e.g., `GAME_MODIFIED.BLB`)
4. Click **Save**
5. The exporter will:
   - Extract all node properties
   - Validate the data
   - Pack binary structures (TileHeader, LayerEntry, EntityDef)
   - Build BLB segments with proper TOC entries
   - Write a valid BLB file with sector alignment
6. Check the Output console for validation messages

### Step 6: Verify the Export

#### Quick Verification
Check the console output. You should see:
```
[BLBExporter] Validation passed: X layers, Y entities
[BLBExporter] Packing BLB data...
[BLBExporter] Successfully exported to: GAME_MODIFIED.BLB
```

#### Deep Verification: Re-import
1. In the BLB Browser, click **"Open BLB..."** again
2. Select your exported `GAME_MODIFIED.BLB`
3. Open the same level/stage
4. Verify all your changes are preserved:
   - Background color should be blue (or whatever you set)
   - Entity should be at the new position `(200, 150)`
   - Entity dimensions should match your edits
   - Layer parallax should be `0x8000`
   - Fog color should match if you changed it

### Step 7: Binary Verification (Advanced)

If you want to verify the binary structure:

```bash
# Check file size (should be reasonable, not bloated)
ls -lh GAME_MODIFIED.BLB

# View header (first 4096 bytes)
hexdump -C GAME_MODIFIED.BLB | head -n 256

# Verify level count at offset 0xF31
hexdump -s 0xF31 -n 1 -C GAME_MODIFIED.BLB

# Check level entry at offset 0x00
hexdump -s 0x00 -n 112 -C GAME_MODIFIED.BLB
```

## Expected Results

### Success Criteria

✅ **Background Color**: Exported BLB contains correct RGB values at TileHeader offset 0x00-0x02

✅ **Entity Position**: Entity x_center/y_center values match your edits (offset 0x08-0x0B in EntityDef)

✅ **Entity Dimensions**: Entity x1/y1/x2/y2 values match your edits (offset 0x00-0x07)

✅ **Layer Parallax**: Layer scroll_x value is 0x8000 in LayerEntry (offset 0x10-0x13)

✅ **Re-import Fidelity**: Re-importing the exported BLB shows all modifications

✅ **File Validity**: Exported BLB has proper header, TOC entries, and sector alignment

### What to Check

1. **File Size**: Should be reasonable (typically a few MB for a single level)
2. **Header**: Offset 0xF31 should contain level count = 1
3. **Level Entry**: Offset 0x00-0x70 should contain valid sector offsets
4. **Sector Alignment**: All segments should be padded to 2048-byte boundaries
5. **TOC Structure**: Each segment should have a valid TOC with asset count + entries
6. **Asset Order**: Secondary should have Asset 100 (tile header), Tertiary should have 201 (layers), 200 (tilemaps), 501 (entities)

## Troubleshooting

### Export Failed

If export fails, check the Output console for specific error messages:

- **"Invalid level dimensions"**: Ensure `level_width` and `level_height` are > 0
- **"No layers to export"**: Scene must have at least one layer
- **"Layer tilemap size mismatch"**: Layer dimensions don't match tilemap data size
- **"Entity has invalid bounding box"**: x1 must be < x2, y1 must be < y2

### Re-import Shows Wrong Values

If re-import doesn't show your changes:

1. Verify the export succeeded (check console)
2. Make sure you're opening the exported BLB, not the original
3. Check that you saved the scene before exporting
4. Try exporting again with a different filename

### Field Not Editable

If a field appears but can't be edited:

1. Make sure the node has the correct script (BLBStageRoot, BLBLayer, BLBEntity)
2. Check that you're editing the node, not its children
3. Some fields may be read-only depending on node type

## Notes

- The current implementation creates a minimal BLB with one level and one stage
- Multi-level BLB export requires additional work (tracked separately)
- Tile pixels and palettes are not yet re-packable (would need image → indexed conversion)
- The exported BLB uses simplified segment layout but is structurally valid

## Next Steps

After successful round-trip testing:

1. Try more complex edits (multiple layers, many entities)
2. Test with different levels from the original BLB
3. Create custom levels from scratch in Godot
4. Implement tile/palette re-packing for complete asset replacement

