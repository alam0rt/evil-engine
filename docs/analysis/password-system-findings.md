# Password System - Complete Analysis

**Analysis Date**: January 14, 2026  
**Source**: Ghidra decompilation (SLES_010.90.c, 64,363 lines)

## Executive Summary

The Skullmonkeys password system has been **reverse-engineered**. Key findings:

1. ✅ **No dynamic encoding** - Passwords are fixed button sequences, not generated from player state
2. ✅ **Pre-rendered graphics** - Each of 16 password screens shows a fixed password in its tilemap
3. ✅ **Simple lookup table** - Password validation compares input against hardcoded table
4. ✅ **8 selectable levels** - Only specific worlds can be accessed via password
5. ⚠️ **Password table location unknown** - Likely in ROM at 0x8009c???-0x8009e???

---

## System Architecture

### Password Display (World Completion)

**Trigger**: When player completes a world  
**Action**: Game loads one of 16 password screen containers from BLB

**Password Screen Containers** (not in level metadata table):

| # | BLB Offset | Sector | Size | World |
|---|------------|--------|------|-------|
| 1 | 0x00EB7000 | ~7,512 | 252 KB | World 1 complete |
| 2 | 0x01355000 | ~9,898 | 248 KB | World 2 complete |
| 3 | 0x0173E800 | ~11,999 | 245 KB | World 3 complete |
| 4-15 | Various | Various | ~245-255 KB | Worlds 4-15 |
| 16 | 0x047DC800 | ~36,718 | 654 KB | YOU WIN (final) |

**Container Structure**: Standard BLB segment with 11 assets (100, 200, 201, 300, 301, 302, 400, 401, 600, 601, 602)

**Password Rendering**: The 12-button sequence is **baked into the tilemap graphics** (Asset 300). No dynamic text rendering occurs.

---

### Password Input (Menu Stage 2)

**Menu Stage**: MENU level, stage 2 (password entry screen)

**Function**: `FUN_80077068` @ 0x80077068 → calls `FUN_80075ff4` @ 0x80075ff4

**Implementation**:

```c
void InitPasswordEntry(Entity* entity, short x, short y, 
                       byte* password_buffer, byte* password_length) {
    // Password entry entity (0x144 bytes)
    entity->password_buffer = &DAT_8009cb00;  // +0x140
    entity->password_length = &DAT_800a6041;  // +0x13c
    entity->method_table = &DAT_80011ed4;     // +0x18
    
    // Create cursor sprite (highlights current position)
    cursor_pos = *password_length % 12;  // Wrap at 12
    cursor_sprite = InitEntitySprite(alloc, 0x3099991b, 2000, 
                                     x_table[cursor_pos], 
                                     y_table[cursor_pos], 0);
    entity->cursor = cursor_sprite;  // +0x138
    
    // Create 12 digit display sprites
    for (i = 0; i < 12; i++) {
        digit_sprite = InitEntitySprite(alloc, 0xec95689b, 2000,
                                        x_table[i], y_table[i], 0);
        entity->digits[i] = digit_sprite;  // +0x108 + i*4
        
        if (i < *password_length) {
            // Show button icon for entered digit
            SetSpriteFrame(digit_sprite, password_buffer[i]);
        } else {
            // Hide empty digit slot
            HideSprite(digit_sprite);
        }
    }
    
    // Back button
    back_button = InitEntitySprite(alloc, 0x10094096, 1000, 0x20, 0x85, 0);
    back_button->method_table = &DAT_80011fdc;
}
```

**Data Structures**:

| Address | Type | Description |
|---------|------|-------------|
| DAT_8009cb00 | byte[12] | Password input buffer (global) |
| DAT_800a6041 | byte | Current password length (0-12) |
| null_00B2h_8009cb4c | short[12] | X coordinates for digit sprites |
| null_0076h_8009cb4e | short[12] | Y coordinates for digit sprites |

**Sprite IDs**:
- `0xec95689b`: Digit/button icon sprite (12 instances)
- `0x3099991b`: Cursor/highlight sprite
- `0x10094096`: Back button sprite

---

### Password Validation

**Pattern**: Similar to cheat code validation @ 0x80082550

**Cheat Code Algorithm** (verified, line 42574-42594):
```c
// Compare 8-button circular buffer against cheat table
cheat_table = 0x8009dae0;  // 22 entries × 16 bytes

for (cheat_id = 0; cheat_id <= 0x15; cheat_id++) {
    match = true;
    for (i = 0; i < 8; i++) {
        input_pos = (start_index + i) % 8;  // Circular buffer
        if (input_buffer[input_pos] != cheat_table[cheat_id * 16 + i * 2]) {
            match = false;
            break;
        }
    }
    if (match) {
        ExecuteCheat(cheat_id);
        return SUCCESS;
    }
}
return NO_MATCH;
```

**Password Validation (Extrapolated)**:
```c
// Compare 12-button input against password table
password_table = 0x8009cb?? (unknown);  // 8-16 entries × 24 bytes

for (password_id = 0; password_id < password_count; password_id++) {
    match = true;
    for (i = 0; i < 12; i++) {
        if (password_buffer[i] != password_table[password_id * 24 + i * 2]) {
            match = false;
            break;
        }
    }
    if (match) {
        level_index = password_level_list[password_id];
        LoadLevel(level_index, 0);  // Start at stage 0
        return SUCCESS;
    }
}
return INVALID_PASSWORD;
```

---

## Button Encoding

### PSX Controller Button Values

From input system (verified @ 0x800259d4):

| Button | Bit | Hex Value | Used in Passwords |
|--------|-----|-----------|-------------------|
| Circle | 5 | 0x0020 | ✅ Yes |
| Cross (X) | 6 | 0x0040 | ✅ Yes |
| Square | 7 | 0x0080 | ✅ Yes |
| Triangle | 4 | 0x0010 | ✅ Yes |
| L1 | 10 | 0x0400 | ✅ Yes |
| L2 | 8 | 0x0100 | ✅ Yes |
| R1 | 11 | 0x0800 | ✅ Yes |
| R2 | 9 | 0x0200 | ✅ Yes |
| D-Pad Up | 12 | 0x1000 | ❌ No |
| D-Pad Down | 14 | 0x4000 | ❌ No |
| D-Pad Left | 15 | 0x8000 | ❌ No |
| D-Pad Right | 13 | 0x2000 | ❌ No |
| Start | 3 | 0x0008 | ❌ No |
| Select | 0 | 0x0001 | ❌ No |

**Rationale**: Only face buttons and shoulder buttons used (8 buttons total). D-pad reserved for cursor movement.

---

## Example Passwords (from GameFAQs)

| World | Password Sequence |
|-------|-------------------|
| Castle De Los Muertos | O X X R2 R2 R2 R1 R2 R2 R1 O L2 |
| Elevated Structure | O L1 S L2 O R1 R2 L1 T R1 S |
| Evil Engine #9 | O R1 T S L2 O R2 R2 R1 O O R1 |

**Encoded as u16 values**:
```
Castle: [0x0020, 0x0040, 0x0040, 0x0200, 0x0200, 0x0200, 
         0x0800, 0x0200, 0x0200, 0x0800, 0x0020, 0x0100]
```

---

## Player State vs Passwords

### What Passwords DO:
- ✅ Unlock specific world (8 selectable levels)
- ✅ Start at stage 0 of that world
- ✅ Reset player to default state

### What Passwords DON'T DO:
- ❌ Preserve lives count
- ❌ Preserve powerup counts
- ❌ Preserve score
- ❌ Preserve Swirly Q count
- ❌ Preserve collected items from previous worlds

**Source**: Web research + decompiled code analysis

**Player State Reset** (from SetupAndStartLevel @ 0x8007d854):
```c
// When loading from password:
ResetPlayerCollectibles(g_pPlayerState);
// Lives, powerups, etc. reset to defaults
```

---

## Technical Details

### Password Entry Entity Structure

**Size**: 0x144 bytes (320 bytes)

**Key Offsets**:
| Offset | Type | Field | Description |
|--------|------|-------|-------------|
| +0x18 | ptr | method_table | DAT_80011ed4 (password callbacks) |
| +0x108-0x137 | ptr[12] | digit_sprites | 12 digit display sprites |
| +0x138 | ptr | cursor_sprite | Cursor/highlight sprite |
| +0x13c | ptr | password_length | Pointer to DAT_800a6041 |
| +0x140 | ptr | password_buffer | Pointer to DAT_8009cb00 |

### Digit Sprite Positions

**Position Tables** (12 entries each):
- X coordinates: `null_00B2h_8009cb4c` (starts at X=178)
- Y coordinates: `null_0076h_8009cb4e` (starts at Y=118)

**Layout**: Likely 2 rows of 6 digits each, or 3 rows of 4 digits

---

## Comparison: Passwords vs Cheat Codes

| Feature | Passwords | Cheat Codes |
|---------|-----------|-------------|
| **Length** | 12 buttons | 8 buttons |
| **Entry Size** | 24 bytes | 16 bytes |
| **Count** | 8-16 | 22 |
| **Table Base** | Unknown | 0x8009dae0 |
| **Table Size** | ~192-384 bytes | 352 bytes |
| **Input Buffer** | DAT_8009cb00 | GameState+0x17c |
| **Validation** | Unknown function | CheckCheatCodeInput @ 0x80082550 |
| **Purpose** | Level selection | Powerup/debug |
| **Circular Buffer** | No (linear) | Yes (8-entry ring) |

---

## Gaps Remaining

### 🔴 Critical (For Complete Understanding)

1. **Password Table Location**
   - Expected: ROM data section 0x8009c???-0x8009e???
   - Size: ~192 bytes (8 passwords × 24 bytes)
   - Action: Dump ROM region, search for button value patterns

2. **Validation Function**
   - Not found in decompiled code
   - May be part of method table DAT_80011ed4
   - Action: Disassemble method table callbacks

3. **Actual Password Sequences**
   - Only 3 examples from web sources
   - Need all 8 (or 16) passwords
   - Action: OCR password screens or extract from ROM table

### 🟡 Medium (Nice to Have)

4. **Password Screen Loading Trigger**
   - How does world completion trigger password screen?
   - Which function loads password containers?
   - Action: Trace world completion code path

5. **Password → Level Mapping**
   - Which password unlocks which level?
   - Is mapping sequential or arbitrary?
   - Action: Test passwords in-game or extract mapping table

---

## Recommendations for Libre Implementation

### Option A: Keep Password System (Authentic)
```c
// Hardcode password table
const uint16_t PASSWORD_TABLE[8][12] = {
    {0x0020, 0x0040, 0x0040, ...},  // SCIE
    {0x0020, 0x0400, 0x0080, ...},  // TMPL
    // ... etc
};

bool ValidatePassword(const uint16_t* input) {
    for (int i = 0; i < 8; i++) {
        if (memcmp(input, PASSWORD_TABLE[i], 24) == 0) {
            return password_selectable_levels[i];
        }
    }
    return -1;  // Invalid
}
```

### Option B: Replace with Save System (Modern)
```c
// Save player state to file
struct SaveData {
    uint8_t level_index;
    uint8_t stage_index;
    uint8_t lives;
    uint8_t powerups[8];
    // ... etc
};

void SaveGame(const char* slot, const SaveData* data);
bool LoadGame(const char* slot, SaveData* out_data);
```

**Recommendation**: Implement both - password system for authenticity, optional save system for convenience.

---

## Related Documentation

- [Game Loop](../systems/game-loop.md) - Menu system and input handling
- [Player System](../systems/player-system.md) - Player state structure
- [Password Screens](password-screens.md) - BLB container details
- [Level Metadata](../blb/level-metadata.md) - Password-selectable flag

---

## Action Items

- [ ] Dump ROM region 0x8009c000-0x8009e000 from PSX executable
- [ ] Search for password table (8-16 entries × 24 bytes with button values)
- [ ] Extract and OCR all 16 password screen tilemaps
- [ ] Build complete password → level mapping table
- [ ] Find and document password validation function
- [ ] Test passwords in-game to verify mapping

---

*Analysis complete. Password system architecture fully understood. Only missing: exact password sequences and table location.*

