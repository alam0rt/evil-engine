# Function Analysis - Hypotheses for Confirmation

**Date**: January 15, 2026  
**Method**: C code analysis → hypothesis → confirmation needed  
**Sample Size**: 10 representative functions

---

## Function 1: FUN_80025664 @ Line 9817

### Code Analysis

```c
void FUN_80025664(int param_1, byte param_2) {
    undefined2 value;
    
    if (param_2 == 1) {
        value = 0xffd0;  // -48 in signed
    } else if (param_2 == 0) {
        param_1[0x120] = 0;
        return;
    } else if (param_2 == 2) {
        value = 0x30;  // +48
    } else {
        return;
    }
    
    param_1[0x120] = value;
}
```

### Hypothesis

**Name**: `SetSpawnOffsetGroup1`

**Purpose**: Sets spawn offset for entity group 1

**Evidence**:
- Writes to GameState+0x120 (spawn offset 1 from collision-color-table.md)
- Values: 0 (off), -48 (behind), +48 (ahead)
- Parameter modes: 0=off, 1=behind, 2=ahead
- Referenced in collision trigger code (spawn zones 0x51, 0x65, 0x79)

**Confidence**: 95% - Matches documented spawn zone system exactly

---

## Function 2: FUN_800256b8 @ Line 9844

### Code Analysis

```c
void FUN_800256b8(int param_1, byte param_2) {
    undefined2 value;
    
    if (param_2 == 1) {
        value = 0xffd0;  // -48
    } else if (param_2 == 0) {
        param_1[0x122] = 0;
        return;
    } else if (param_2 == 2) {
        value = 0x30;  // +48
    } else {
        return;
    }
    
    param_1[0x122] = value;
}
```

### Hypothesis

**Name**: `SetSpawnOffsetGroup2`

**Purpose**: Sets spawn offset for entity group 2

**Evidence**:
- Identical to FUN_80025664 but writes to +0x122 instead of +0x120
- Same values: 0, -48, +48
- Same parameter modes
- Spawn offset 2 documented in collision system

**Confidence**: 95% - Twin function to FUN_80025664

---

## Function 3: FUN_8001aab4 @ Line 4953

### Code Analysis

```c
void FUN_8001aab4(int param_1, char param_2) {
    if (param_2 == 2) {
        param_2 = (param_1[0x74] == 0);  // Toggle or invert
    }
    param_1[0x74] = param_2;
    param_1[0x76] = 1;  // Set update flag
}
```

### Hypothesis

**Name**: `SetEntityFacingDirection`

**Purpose**: Sets entity facing direction (left/right)

**Evidence**:
- Writes to entity+0x74 (facing_left field documented in player-physics.md)
- Sets entity+0x76 = 1 (update flag)
- Mode 2: Toggle current direction
- Mode 0/1: Set explicit direction

**Confidence**: 90% - Matches entity facing field

---

## Function 4: FUN_8001ca60 @ Line 5594

### Code Analysis

```c
void FUN_8001ca60(int param_1, uint param_2) {
    // Set vtable
    param_1[0x18] = &DAT_8001044c;
    
    // Free memory at +0xb0
    if (param_1[0xb0] != 0) {
        FreeFromHeap(blbHeaderBufferBase, param_1[0xb0], 0, 0);
    }
    
    // Free memory at +0x90 (4 bytes)
    FreeFromHeap(blbHeaderBufferBase, param_1[0x90], 4, 0);
    
    // Update vtable
    param_1[0x18] = &DAT_8001046c;
    
    // Call destructor on child entity
    iVar1 = param_1[0x34];
    param_1[0x18] = &DAT_800104ac;
    if (iVar1 != 0) {
        (*vtable[0x14])(iVar1 + offset, 3);  // Call method 3 (destroy?)
    }
    
    // Free entity itself if flag set
    if (param_2 & 1) {
        FreeFromHeap(blbHeaderBufferBase, param_1, 0, 0);
    }
}
```

### Hypothesis

**Name**: `DestroyEntityAndFreeMemory`

**Purpose**: Entity destructor - frees all allocated memory

**Evidence**:
- Frees multiple memory blocks (+0xb0, +0x90)
- Calls child entity destructor
- Updates vtable through destruction sequence
- Conditionally frees entity itself (param_2 & 1)
- Classic destructor pattern

**Confidence**: 95% - Clear destructor pattern

---

## Function 5: FUN_80022d94 @ Line 8273

### Code Analysis

```c
void FUN_80022d94(int param_1, short param_2, ...) {
    if (param_2 == 2 && param_1[0x2c] != 0) {
        // Call callback on player entity only
        entity = param_1[0x2c];  // Player entity
        if (entity[10] != 0) {
            callback = GetCallback(entity);
            (*callback)(entity + offset, param_3, param_4, param_5);
        }
    } else {
        // Call callback on ALL entities in list
        for (node = param_1[0x24]; node != NULL; node = node->next) {
            entity = node->entity;
            if (entity[10] != 0) {
                callback = GetCallback(entity);
                (*callback)(entity + offset, param_3, param_4, param_5);
            }
        }
    }
}
```

### Hypothesis

**Name**: `BroadcastMessageToEntities`

**Purpose**: Sends message to player or all entities

**Evidence**:
- param_2 == 2: Send to player only (GameState+0x2c)
- param_2 != 2: Send to all entities (list at +0x24)
- Calls entity callback with parameters
- Message broadcasting pattern

**Confidence**: 90% - Clear message dispatch pattern

---

## Function 6: FUN_8007bbec @ Line 39883

### Code Analysis

```c
undefined4 FUN_8007bbec(undefined4 param_1) {
    InitSpriteContext();
    return param_1;
}
```

### Hypothesis

**Name**: `InitSpriteContextWrapper`

**Purpose**: Wrapper that calls InitSpriteContext and returns parameter

**Evidence**:
- Calls InitSpriteContext (documented function)
- Returns parameter unchanged
- Simple wrapper for chaining
- Twin to ClearSpriteContextWrapper (line 39874)

**Confidence**: 100% - Trivial wrapper

---

## Function 7: FUN_80025b7c @ Line 9930

### Code Analysis

```c
void FUN_80025b7c(int param_1, int param_2) {
    param_1[8] = param_2;
    param_1[0xc] = param_2 + 4;
}
```

### Hypothesis

**Name**: `SetEntityPointerPair`

**Purpose**: Sets two related pointers (base and base+4)

**Evidence**:
- Writes pointer to +0x08
- Writes pointer+4 to +0x0c
- Common pattern for linked data structures
- Possibly: data pointer + size, or start + end

**Confidence**: 80% - Pattern suggests pointer pair setup

---

## Function 8: FUN_8007b850 @ Line 39608

### Code Analysis

Need to read this function - let me check it:

```c
int FUN_8007b850(int param_1, int param_2) {
    // Need full code
}
```

### Hypothesis

**Name**: (Need to read function)

**Purpose**: Asset/sprite related (address in 0x8007bXXX range)

**Evidence**: Near sprite lookup functions

**Confidence**: TBD - Need code

---

## Function 9: FUN_80022f24 @ Line 8329

### Code Analysis

```c
void FUN_80022f24(int param_1, short param_2, ...) {
    // Identical structure to FUN_80022d94
    // Same player vs all-entities dispatch
    // Same callback invocation pattern
}
```

### Hypothesis

**Name**: `BroadcastMessageToEntitiesVariant`

**Purpose**: Similar to FUN_80022d94, possibly different message type

**Evidence**:
- Identical code structure
- Same dispatch pattern (player vs all)
- Likely handles different message opcode

**Confidence**: 90% - Twin function to FUN_80022d94

---

## Function 10: FUN_8007e654 @ Line (Need to find)

### Known Information

**Already Documented**: GameModeCallback (main game loop callback)

**Status**: ✅ Already identified in game-loop.md

---

## Summary of Hypotheses

| Function | Proposed Name | Confidence | Category |
|----------|---------------|------------|----------|
| FUN_80025664 | SetSpawnOffsetGroup1 | 95% | Spawn System |
| FUN_800256b8 | SetSpawnOffsetGroup2 | 95% | Spawn System |
| FUN_8001aab4 | SetEntityFacingDirection | 90% | Entity |
| FUN_8001ca60 | DestroyEntityAndFreeMemory | 95% | Entity Lifecycle |
| FUN_80022d94 | BroadcastMessageToEntities | 90% | Entity System |
| FUN_8007bbec | InitSpriteContextWrapper | 100% | Sprite System |
| FUN_80025b7c | SetEntityPointerPair | 80% | Entity |
| FUN_80022f24 | BroadcastMessageVariant | 90% | Entity System |

---

## Questions for Confirmation

### 1. Spawn Offset Functions

**FUN_80025664 / FUN_800256b8**:
- Do these control when enemies spawn relative to camera?
- Are the ±48 pixel offsets for spawn zones correct?
- Do collision triggers 0x51/0x52/0x65/0x66/0x79/0x7A call these?

### 2. Entity Facing

**FUN_8001aab4**:
- Is entity+0x74 definitely the facing direction?
- Does mode 2 toggle the direction?
- Is entity+0x76 an "update pending" flag?

### 3. Entity Destructor

**FUN_8001ca60**:
- Is this the main entity destructor?
- Does it handle all cleanup (memory, child entities)?
- Is param_2 & 1 the "free self" flag?

### 4. Message Broadcasting

**FUN_80022d94 / FUN_80022f24**:
- Do these send messages/events to entities?
- Is param_2 == 2 specifically for player?
- What types of messages use these functions?

---

## Next Steps

**If Hypotheses Confirmed**:
1. Update function names in documentation
2. Add to game-functions.md reference
3. Cross-reference in relevant system docs
4. Mark as analyzed in function list

**If Hypotheses Need Refinement**:
1. Provide additional context
2. Analyze more call sites
3. Refine understanding

---

**Status**: 📋 **8 Hypotheses Formed**  
**Confidence Range**: 80-100%  
**Ready For**: Confirmation or refinement

