# Collision Color Table & Item Pickups

**Source**: PlayerProcessTileCollision analysis  
**Date**: January 14, 2026  
**Status**: System documented, table extraction needed

This document details the color zone system and item pickup system discovered in tile collision trigger handling.

---

## Color Zone System (Trigger Types 0x15-0x28)

### Overview

Trigger zones in range 0x15-0x28 (21-40 decimal) apply RGB color modulation to the player sprite for environmental effects.

### Handler Function

**FUN_8007ee6c** @ 0x8007ee6c (GetColorZoneRGB):

```c
bool GetColorZoneRGB(GameState* state, u8 trigger_type,
                     u8* out_r, u8* out_g, u8* out_b) {
    u8 index = trigger_type - 0x15;  // Convert to 0-based (0-19)
    
    if (index < 0x14) {  // 20 valid entries
        int offset = index * 3;  // RGB = 3 bytes per entry
        
        *out_r = ColorTable[offset + 0];  // @ ROM 0x8009d9c0
        *out_g = ColorTable[offset + 1];  // @ ROM 0x8009d9c1
        *out_b = ColorTable[offset + 2];  // @ ROM 0x8009d9c2
        
        return true;
    }
    
    return false;  // Out of range
}
```

### Color Table Structure

**ROM Location**: 0x8009d9c0  
**Size**: 60 bytes (20 RGB triplets)  
**Format**: `[R, G, B, R, G, B, ...]` (u8 values 0-255)

**Trigger Type to Table Index**:
```
Trigger 0x15 (21) → Color[0]  (bytes 0-2)
Trigger 0x16 (22) → Color[1]  (bytes 3-5)
...
Trigger 0x28 (40) → Color[19] (bytes 57-59)
```

### Output Destination

**Player Entity Fields**:
- `player[0x15d]`: Red component (u8)
- `player[0x15e]`: Green component (u8)
- `player[0x15f]`: Blue component (u8)

These values are likely used for sprite RGB modulation (tinting).

### Typical Color Zone Uses

Based on common PSX platformer conventions:

| Index | Trigger | Likely Color | Use Case |
|-------|---------|--------------|----------|
| 0-3 | 0x15-0x18 | Blue tints | Underwater zones |
| 4-7 | 0x19-0x1C | Red/orange | Lava zones |
| 8-11 | 0x1D-0x20 | Gray | Fog/smoke zones |
| 12-15 | 0x21-0x24 | Green | Toxic zones |
| 16-19 | 0x25-0x28 | Purple/special | Magic zones |

**Note**: Actual colors need to be extracted from ROM dump.

---

## Extraction Method

### Option 1: From ROM File

```bash
# Extract from PSX executable
dd if=SLES_010.90 bs=1 skip=$((0x9d9c0)) count=60 | hexdump -C > color_table.txt

# Parse into RGB values
python3 << 'EOF'
with open('color_table_dump.bin', 'rb') as f:
    data = f.read(60)
    for i in range(20):
        r, g, b = data[i*3:(i+3)*3]
        print(f"Color {i:2d} (Trigger 0x{i+0x15:02X}): RGB({r:3d}, {g:3d}, {b:3d})")
EOF
```

### Option 2: From PCSX-Redux Memory

```lua
-- In PCSX-Redux Lua console
local addr = 0x8009d9c0
for i = 0, 19 do
    local r = PCSX.getMemoryByte(addr + i*3 + 0)
    local g = PCSX.getMemoryByte(addr + i*3 + 1)
    local b = PCSX.getMemoryByte(addr + i*3 + 2)
    print(string.format("Color %2d (0x%02X): RGB(%3d, %3d, %3d)", 
                        i, i+0x15, r, g, b))
end
```

---

## Item Pickup System (Trigger Types 0x32-0x3B)

### Overview

Trigger zones in range 0x32-0x3B (50-59 decimal) represent **10 collectible item types**.

### Handler Code

From PlayerProcessTileCollision default case (lines 17808-17814):

```c
default:
    u8 item_index = (trigger_type - 0x32) & 0xFF;
    
    if (item_index < 10) {  // Items 0-9
        if (g_pPlayerState[item_index + 6] == 0) {
            g_pPlayerState[item_index + 6] = 1;  // Mark collected
            FUN_8001c4a4(player, 0x7003474c);    // Play collection sound
        }
    }
    // else: generic trigger handler
    break;
```

### Item Storage

**Global Array**: `g_pPlayerState[]` (player save state)

**Storage Locations**:
| Item Index | Trigger Value | Storage Location | Bit/Flag |
|------------|---------------|------------------|----------|
| 0 | 0x32 (50) | g_pPlayerState[6] | 0 or 1 |
| 1 | 0x33 (51) | g_pPlayerState[7] | 0 or 1 |
| 2 | 0x34 (52) | g_pPlayerState[8] | 0 or 1 |
| 3 | 0x35 (53) | g_pPlayerState[9] | 0 or 1 |
| 4 | 0x36 (54) | g_pPlayerState[10] | 0 or 1 |
| 5 | 0x37 (55) | g_pPlayerState[11] | 0 or 1 |
| 6 | 0x38 (56) | g_pPlayerState[12] | 0 or 1 |
| 7 | 0x39 (57) | g_pPlayerState[13] | 0 or 1 |
| 8 | 0x3A (58) | g_pPlayerState[14] | 0 or 1 |
| 9 | 0x3B (59) | g_pPlayerState[15] | 0 or 1 |

**Collection Behavior**:
- One-time pickup (flag prevents re-collection)
- Sound effect: 0x7003474c (collection sound)
- Likely persists across checkpoints/deaths

### Item Type Identification

**To find what each item represents**, search for:

```bash
# Direct reads of these indices
grep "g_pPlayerState\[6\]" SLES_010.90.c   # Item 0
grep "g_pPlayerState\[7\]" SLES_010.90.c   # Item 1
# ... etc

# Array accesses
grep "g_pPlayerState\[.*\+ 6\]" SLES_010.90.c
```

**Actual Item Types** (from items.md reference):

Based on g_pPlayerState array analysis:

| Index | Trigger | g_pPlayerState | Item Name | Max | Description |
|-------|---------|----------------|-----------|-----|-------------|
| 0-9 | 0x32-0x3B | [6-15] | **Zone Collection Flags** | 1 each | Per-zone collectibles |

**Note**: The 10 item slots at g_pPlayerState[6-15] are used for **zone-specific collection tracking**, not individual item types.

**Actual Collectible Items** (stored elsewhere):
- **Clayballs**: g_pPlayerState[0x12] (100 → 1up)
- **Phoenix Hands**: g_pPlayerState[0x14] (max 7)
- **Phart Heads**: g_pPlayerState[0x15] (max 7)
- **Universe Enemas**: g_pPlayerState[0x16] (max 7)
- **Halo**: g_pPlayerState[0x17] bit 0x01
- **Trail**: g_pPlayerState[0x17] bit 0x02
- **1970 Icons**: g_pPlayerState[0x19] (max 3)
- **Green Bullets**: g_pPlayerState[0x1A] (max 3)
- **Super Willies**: g_pPlayerState[0x1C] (max 7)

**Cross-Reference**: See [items.md](../reference/items.md) for complete item documentation.

---

## Spawn Offset System

### Storage Locations

From spawn control functions (FUN_80025664, FUN_800256b8):

| GameState Offset | Field | Spawn Group | Values |
|------------------|-------|-------------|--------|
| 0x120 | spawn_offset_1 | Group 1 | 0, -48, +48 |
| 0x122 | spawn_offset_2 | Group 2 | 0, -48, +48 |

### Offset Modes

| Mode | Value | Meaning |
|------|-------|---------|
| 0 (Off) | 0 | Enemies despawned/inactive |
| 1 (On) | -48 | Enemies spawn 48px behind player |
| 2 (Mode2) | +48 | Enemies spawn 48px ahead of player |

### Hypothesis: Camera Culling

The ±48 pixel offsets likely control:
1. **Spawn Distance**: How far from camera center enemies activate
2. **Culling Distance**: How far behind camera enemies despawn
3. **Look-ahead/Behind**: Different modes for forward vs backward scrolling

**Example**:
- Player at X=500, Camera at X=480
- Mode 1 (-48): Spawn enemies at X=432 (48px behind camera)
- Mode 2 (+48): Spawn enemies at X=528 (48px ahead of camera)

### To Verify

Search for reads of `GameState[0x120]` and `GameState[0x122]`:

```bash
# Spawn offset usage
grep "param_1.*0x120\|param_1.*0x122" SLES_010.90.c | grep -v "=" | head -20
```

Look for:
- Entity spawn distance calculations
- Camera position comparisons
- Culling boundary checks

---

## Action Items

### Immediate (This Session)

1. [ ] Extract color table from ROM @ 0x8009d9c0
2. [ ] Document 20 RGB values in this file
3. [ ] Search for g_pPlayerState[6-15] usage to identify items
4. [ ] Document item types in this file

### Follow-Up

1. [ ] Verify spawn offset usage in entity spawn code
2. [ ] Test color zones in-game to confirm tinting behavior
3. [ ] Cross-reference items with level design documents

---

## Status

**Color Zone System**: 90% complete (system documented, table not dumped)  
**Item Pickup System**: 90% complete (system documented, item IDs unknown)  
**Spawn Offset System**: 85% complete (values known, usage hypothesis)

**Next Step**: Extract color table and item type identifications to reach 100%.

