# Function Discoveries and Identifications

**Date**: January 15, 2026  
**Source**: SLES_010.90.c analysis  
**Status**: 🔬 In Progress

---

## Summary

**Total Functions in C Code**: ~1,743 (estimated)  
**Unnamed Functions** (FUN_8XXXXXXX): 144  
**Named Functions**: ~1,599  
**Percentage Named**: ~92%

**Target**: Identify 50-100 additional functions by context analysis

---

## Function Categories

### Animation System Functions (Already Named)

✅ **Complete** (from animation-setters-reference.md):

| Address | Name | Purpose |
|---------|------|---------|
| 0x8001d024 | AllocateSpriteGPUPrimitive | GPU primitive allocation |
| 0x8001d0b0 | SetAnimationSpriteFlags | Set sprite render flags |
| 0x8001d0c0 | SetAnimationFrameIndex | Set current frame |
| 0x8001d0f0 | SetAnimationFrameCallback | Set frame callback |
| 0x8001d170 | SetAnimationLoopFrame | Set loop target |
| 0x8001d1c0 | SetAnimationSpriteId | Change sprite |
| 0x8001d1f0 | SetAnimationSpriteCallback | Set sprite lookup |
| 0x8001d218 | SetAnimationActive | Enable/disable animation |
| 0x8001d290 | TickEntityAnimation | Main animation tick |
| 0x8001d4bc | AdvanceAnimationFrame | Frame advancement |
| 0x8001d548 | ApplyPendingSpriteState | Apply buffered state |
| 0x8001d748 | UpdateSpriteFrameData | Load frame metadata |
| 0x8001e790 | StartAnimationSequence | Start sequence |
| 0x8001e7b8 | StepAnimationSequence | Execute sequence step |
| 0x8001e928 | EntityProcessCallbackQueue | Callback dispatch |
| 0x8001ea64 | EntitySetState | State transition |

**Total**: 16 animation functions ✅

---

### Collision Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x800241f4 | GetTileAttributeAtPosition | Pixel → tile attr |
| 0x80024cf4 | InitTileAttributeState | Load Asset 500 |
| 0x8007b758 | GetTileAttributeUnknown | Read offsets |
| 0x8007b778 | GetTileAttributeDimensions | Read dimensions |
| 0x8007b79c | GetTileAttributeData | Get data pointer |
| 0x800226f8 | CheckEntityCollision | Entity collision |
| 0x8001b360 | CheckPointInBox | Point-in-box test |
| 0x8001b3f0 | CheckBoxOverlap | Box-box overlap |
| 0x80059bc8 | CheckWallCollision | 4-point wall check |
| 0x800245bc | CheckTriggerZoneCollision | Trigger filter |

**Total**: 10 collision functions ✅

---

### Audio Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x8007c388 | PlaySoundEffect | Play sound with pan |
| 0x8007c7e0 | StopAllSPUVoices | Stop all 24 voices |
| 0x8007ca60 | StartCDAudioForLevel | Start CD music |
| 0x8001c4a4 | FUN_8001c4a4 | Entity-relative sound |

🔬 **Need Names** (from function-batches-to-analyze.md):

| Address | Current Name | Proposed Name | Purpose |
|---------|--------------|---------------|---------|
| 0x8007c7b8 | FUN_8007c7b8 | StopSoundEffect | Stop SPU voice |
| 0x8007c818 | FUN_8007c818 | CalculateStereoVolume | Pan → L/R volume |
| 0x8007ca28 | FUN_8007ca28 | SetVoicePanning | Update voice pan |

**Total**: 4 named + 3 need names = 7 audio functions

---

### Physics/Movement Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x80061180 | ApplyEntityPositionUpdate | Update position from velocity |
| 0x800638d0 | PlayerCallback_800638d0 | Player movement + collision |

🔬 **Need Identification** (estimated ~15 functions):

Search patterns:
- Functions accessing entity+0x68/0x6A (position)
- Functions accessing entity+0xB4/0xB8 (velocity)
- Functions accessing entity+0x104/0x108 (alt velocity)
- Functions with gravity constant 0xFFFA0000

**Estimated**: 15-20 physics functions need names

---

### Entity Management Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x800143f0 | AllocateFromHeap | Allocate entity memory |
| 0x800213a8 | AddEntityToSortedRenderList | Add to render list |
| 0x80020b34 | EntityTickLoop | Update all entities |
| 0x80024288 | SpawnOnScreenEntities | Spawn from Asset 501 |
| 0x80020c74 | DeferredEntityRemoval | Remove marked entities |

🔬 **Need Identification** (estimated ~10 functions):

Search patterns:
- Functions with AllocateFromHeap calls
- Functions with AddEntityToSortedRenderList
- Functions managing entity lists
- Entity initialization helpers

**Estimated**: 10-15 entity management functions need names

---

### Level Loading Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x8007d1d0 | InitializeAndLoadLevel | Main level load |
| 0x8007a578 | FUN_8007a578 | Level advance |
| 0x8007ae9c | GetCurrentModeReservedData | Get mode data |
| 0x8007b458 | GetSpawnPosition | Player spawn pos |

**Total**: 4+ level loading functions ✅

---

### Player State Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x80066ce0 | PlayerStateCallback_0 | Idle state |
| 0x80067e28 | Callback_80067e28 | Jump state |
| 0x8005b414 | PlayerTickCallback | Main per-frame update |
| 0x8005a914 | PlayerProcessTileCollision | Tile trigger processing |
| 0x80081e84 | DecrementPlayerLives | Lives management |
| 0x80026162 | ResetPlayerUnlocksByLevel | Reset collectibles |

**Total**: 6+ player functions ✅

---

### Camera Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x800233c0 | UpdateCameraPosition | Smooth scrolling |
| 0x80044f7c | CreateCameraEntity | Camera init |

**Total**: 2 camera functions ✅

---

### Projectile Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x80070414 | SpawnProjectileEntity | Spawn projectile |

**Total**: 1 projectile function ✅

---

### Boss Functions

✅ **Already Named**:

| Address | Name | Purpose |
|---------|------|---------|
| 0x80047fb8 | InitBossEntity | Boss initialization |
| 0x80078200 | CreateBossPlayerEntity | Boss player setup |

**Total**: 2 boss functions ✅

---

## Unknown Function Batches

### Batch 1: Bounding Box Helpers (from function-batches-to-analyze.md)

✅ **Already Identified**:
- 0x8001b360: CheckPointInBox
- 0x8001b3f0: CheckBoxOverlap

### Batch 2: Audio Helpers

🔬 **Need Renaming**:
- 0x8007c7b8: StopSoundEffect (8 lines)
- 0x8007c818: CalculateStereoVolume (80 lines)
- 0x8007ca28: SetVoicePanning (12 lines)

### Batch 3: Entity Sprite Helpers

🔬 **Patterns to Search**:
- Functions with InitEntitySprite calls
- Functions with SetEntitySpriteId
- Functions accessing entity+0x78 (sprite frames pointer)

### Batch 4: Unknown Entity Callbacks (Entity-Specific)

**Large Category**: ~70-80 functions are entity-specific tick callbacks
- These don't need generic names
- Already mapped in entity-types.md by address
- Can be named as "EntityType_XXX_Callback" if needed

---

## Function Identification Progress

| Category | Total Est. | Named | Unnamed | % Named |
|----------|------------|-------|---------|---------|
| Animation | 20 | 16 | 4 | 80% |
| Collision | 15 | 10 | 5 | 67% |
| Audio | 10 | 4 | 6 | 40% |
| Physics | 20 | 2 | 18 | 10% |
| Entity Mgmt | 15 | 5 | 10 | 33% |
| Level Loading | 10 | 4 | 6 | 40% |
| Player | 15 | 6 | 9 | 40% |
| Camera | 5 | 2 | 3 | 40% |
| Entity Callbacks | 80 | 80 | 0 | 100% |
| Misc/Utility | 20 | 5 | 15 | 25% |
| **Total** | **210** | **134** | **76** | **64%** |

**Note**: Entity callbacks are "named" by address mapping in entity-types.md

---

## High-Value Functions to Identify

### Priority 1: Core Systems (10-15 functions)

**Animation** (4 functions):
- Frame lookup helpers
- Animation state validators
- Sequence management utilities

**Physics** (5-8 functions):
- Velocity application functions
- Gravity/acceleration helpers
- Position update utilities

**Collision** (3-5 functions):
- Additional collision shapes
- Trigger zone handlers
- Response callbacks

### Priority 2: Game Logic (15-20 functions)

**Enemy AI** (5-8 functions):
- Common enemy behaviors
- Path following
- Targeting/tracking

**Level** (5-7 functions):
- Asset loading helpers
- State management
- Transition handlers

**Player** (5-10 functions):
- State-specific behaviors
- Powerup application
- Input handlers

### Priority 3: Utilities (10-15 functions)

**Math** (3-5 functions):
- Trigonometry helpers
- Fixed-point conversion
- Random number generation

**Memory** (3-5 functions):
- Heap management
- Buffer operations

**Debug** (2-3 functions):
- Logging/display
- Debug menu

---

## Identification Methodology

### Method 1: Context Analysis

1. Read function code
2. Identify what it accesses (entity fields, globals)
3. Identify what it calls
4. Identify calling functions
5. Deduce purpose from context

### Method 2: Pattern Matching

1. Search for entity offset patterns
2. Group functions by similar patterns
3. Name based on category

### Method 3: Call Graph Analysis

1. Identify root functions (main, callbacks)
2. Trace call chains
3. Name based on caller context

---

## Quick Wins (Already in Docs)

From function-batches-to-analyze.md, these batches are ready to rename:

**Batch 1**: Bounding box helpers (2 functions) - ✅ Already named  
**Batch 2**: Audio helpers (3 functions) - 🔬 Ready to rename  
**Batch 3**: Sprite/CLUT functions (6 functions) - 🔬 Ready to analyze  
**Batch 4**: Input system (4 functions) - 🔬 Ready to analyze  
**Batch 5**: Render helpers (5 functions) - 🔬 Ready to analyze

**Total Quick Wins**: ~20 functions ready for immediate identification

---

## Status

**Functions Identified**: ~134 (64%)  
**Functions Unnamed**: ~76 (36%)  
**High Priority Unnamed**: ~30-40  
**Low Priority** (entity-specific): ~40-50

**Recommendation**: Focus on the 30-40 high-priority core system functions. Entity-specific callbacks can remain as FUN_ addresses (already mapped by entity type).

---

## Related Documentation

- [Function Batches to Analyze](analysis/function-batches-to-analyze.md) - Ready-to-name batches
- [Game Functions](reference/game-functions.md) - Named function reference
- [Animation Framework](systems/animation-framework.md) - Animation function list
- [Collision System](systems/collision-complete.md) - Collision function list

---

**Status**: 📋 **Framework Complete**  
**Immediate Targets**: 20 quick-win functions from existing batches  
**Long-term**: 30-40 high-priority functions  
**Entity Callbacks**: Already mapped, don't need generic names

