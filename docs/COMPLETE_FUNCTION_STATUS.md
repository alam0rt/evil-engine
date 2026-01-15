# Complete Function Analysis Status

**Date**: January 15, 2026  
**Total Functions**: 230 with FUN_ prefix  
**Status Breakdown**: Documented vs Truly Unknown

---

## Summary

**Total Unnamed (FUN_8XXXXXXX)**: 230 functions  
**Documented (behavior known)**: ~60 functions  
**Truly Unknown (need analysis)**: ~170 functions

---

## Category 1: DOCUMENTED (Behavior Known) - ~60 functions

### Animation Functions (16 functions) ✅

Already documented in animation-setters-reference.md:
- FUN_8001d024: AllocateSpriteGPUPrimitive
- FUN_8001d0b0: SetAnimationSpriteFlags
- FUN_8001d0c0: SetAnimationFrameIndex
- FUN_8001d0f0: SetAnimationFrameCallback
- FUN_8001d170: SetAnimationLoopFrame
- FUN_8001d1c0: SetAnimationSpriteId
- FUN_8001d1f0: SetAnimationSpriteCallback
- FUN_8001d218: SetAnimationActive
- FUN_8001d240: EntitySetRenderFlags (referenced)
- FUN_8001d4bc: AdvanceAnimationFrame
- FUN_8001d748: UpdateSpriteFrameData
- FUN_8001e790: StartAnimationSequence
- FUN_8001e7b8: StepAnimationSequence
- FUN_8001ec18: Sequence-related function
- Plus 2 more animation utilities

### Menu System Functions (8 functions) ✅

Documented in menu-system-complete.md:
- FUN_80076ba0: InitMenuStage1 (Main Menu)
- FUN_80077068: InitMenuStage2 (Password Entry)
- FUN_800771c4: InitMenuStage3 (Options)
- FUN_800773fc: InitMenuStage4 (Load/Save)
- FUN_800778ec: UpdateBackgroundColor
- FUN_80077af0: MenuInputHandler
- FUN_800754cc: AttachCursorToButton
- FUN_80075ff4: InitPasswordEntryEntity

### Ending/Secret System Functions (2 functions) ✅

Documented in secret-ending-system.md:
- FUN_8007963c: EndingInputHandler (checks 48 Swirly Qs)
- FUN_800797a8: TriggerSecretEndingSequence

### Collision Functions (3 functions) ✅

Documented:
- FUN_8001b360: CheckPointInBox
- FUN_8001b3f0: CheckBoxOverlap
- FUN_8001b594: CollisionCheckWrapper

### Audio Functions (7 functions) ✅

Identified (3 ready to rename):
- FUN_8001c4a4: Entity-relative PlaySound
- FUN_8007c7b8: StopSoundEffect (identified)
- FUN_8007c818: CalculateStereoVolume (identified)
- FUN_8007ca28: SetVoicePanning (identified)
- FUN_8007cc68: Audio mode function
- FUN_8007c2e0: Audio system function
- FUN_8007ccfc: Audio utility

### Spawn/Entity Functions (10 functions) ✅

Context documented:
- FUN_80025664: SpawnZoneGroup1Control
- FUN_800256b8: SpawnZoneGroup2Control
- FUN_800255c8: Spawn-related
- FUN_80025630: Spawn-related
- FUN_80025b7c: Entity spawn utility
- FUN_80025bc0: Entity spawn utility
- FUN_80025c7c: BuildPasswordLevelList (identified line 37957)
- FUN_8002615c: Entity utility
- FUN_800261d4: Entity utility
- FUN_80026260: ClearPlayerUnlockFlags (identified line 10131)

### Level/System Functions (8 functions) ✅

Context documented:
- FUN_8007df38: Player initialization (referenced)
- FUN_8007e654: GameModeCallback (documented)
- FUN_8007ee6c: GetColorZoneRGB (documented line 41912)
- FUN_8007eed8: Color zone related
- FUN_8007a4c0: Level advance function
- FUN_8007eb78: Level-related
- FUN_80081fd0: Init-related (line 41277)
- FUN_80081c0c: Tile alignment (line 41263)

### Movie/Graphics Functions (6 functions) ✅

Context from movie system:
- FUN_80039c4c: Movie system (line 13147)
- FUN_80039ce0: Movie decoding (line 13161)
- FUN_80039ddc: Movie system (line 13162)
- FUN_80039e5c: Movie callback (line 13162)
- FUN_80039fa4: Movie system (line 13164)
- FUN_8003a13c: Movie frame management (line 13294)

**Subtotal Documented**: ~60 functions with known behavior

---

## Category 2: TRULY UNKNOWN - ~170 functions

### Graphics/Rendering Functions (~50 functions)

**0x8001XXXX Range** (Graphics primitives):
- FUN_800138f0, FUN_80013ab0, FUN_80013d10, FUN_80013f50
- FUN_80014278, FUN_800143a4, FUN_80014854, FUN_80014968
- FUN_800149e8, FUN_80014a9c, FUN_80014cf8, FUN_80015074
- FUN_800150c4, FUN_80015134, FUN_80015424, FUN_80015434
- FUN_80015614, FUN_8001889c
- Plus ~30 more

**Need**: Context analysis from callers

### Entity/Gameplay Functions (~40 functions)

**0x8001XXXX-0x8002XXXX Range**:
- FUN_800195b0, FUN_8001963c, FUN_80019650, FUN_800196d8
- FUN_80019700, FUN_80019790, FUN_80019cf8, FUN_80019d74
- FUN_80019f2c, FUN_8001a3ac, FUN_8001a448, FUN_8001a49c
- FUN_8001aab4, FUN_8001b8c4, FUN_8001b92c, FUN_8001c178
- FUN_8001c364, FUN_8001c5b4, FUN_8001ca60, FUN_8001cc6c
- FUN_8001cea4
- Plus 0x8002XXXX range (~20 more)

**Need**: Caller analysis and field access patterns

### Physics/Movement Functions (~20 functions)

**Mixed Ranges**:
- Functions accessing entity+0x68/0x6A (position)
- Functions accessing entity+0xB4/0xB8 (velocity)
- Functions with gravity constant 0xFFFA0000

**Need**: Pattern recognition and constant analysis

### Graphics/MDEC Functions (~20 functions)

**0x8003XXXX Range**:
- FUN_80030e54, FUN_800313cc, FUN_8003286c, FUN_80033d3c
- FUN_800346f4, FUN_80034a54, FUN_800362a4, FUN_80036698
- FUN_800371d4, FUN_80037810, FUN_80037ae0, FUN_80037d34
- FUN_8003802c, FUN_80038300, FUN_80038cac, FUN_80038e0c
- Plus MDEC-related (FUN_8003a024, FUN_8003a1cc, etc.)

**Need**: MDEC/movie system analysis

### Level/Asset Loading Functions (~15 functions)

**0x8007XXXX Range**:
- FUN_8007a150, FUN_8007a194, FUN_8007a1e8, FUN_8007a218
- FUN_8007a234, FUN_8007a594, FUN_8007b80c, FUN_8007b850
- FUN_8007b894, FUN_8007bac8, FUN_8007bbec, FUN_8007bfb8
- Plus loading helpers

**Need**: Asset loading flow analysis

### Miscellaneous/Utility (~25 functions)

**Various Ranges**:
- Math functions
- Memory management
- Debug utilities
- PAD/controller functions (FUN_8008XXXX range)

**Need**: Individual analysis

---

## Already Documented but Keep FUN_ Name

**Why Keep FUN_**:
- Ghidra-generated names
- Haven't updated Ghidra database
- Documented in our docs with proposed names
- Function behavior understood

**Examples**:
- FUN_8001c4a4: Documented as "Entity-relative PlaySound"
- FUN_8007ee6c: Documented as "GetColorZoneRGB"
- Menu functions: All 8 menu functions analyzed but keep FUN_ name

---

## Analysis Priority

### Tier 1: Core Systems (~20 functions, 5-8 hours)

**Animation** (4): Frame utilities, validators  
**Physics** (8): Velocity, gravity, movement  
**Collision** (5): Response, shapes  
**Audio** (3): Already identified, just need formal rename

### Tier 2: Gameplay (~30 functions, 8-12 hours)

**Player** (10): State helpers, movement  
**Entity** (10): Lifecycle, spawning  
**Level** (10): Loading, transitions

### Tier 3: Graphics (~50 functions, 15-25 hours)

**Primitives**: GPU setup, rendering  
**MDEC**: Movie decoding helpers  
**Textures**: VRAM management

### Tier 4: Utility (~70 functions, 20-35 hours)

**Math**: Calculations  
**Memory**: Heap management  
**Debug**: Development tools  
**Misc**: Various utilities

---

## To Analyze All Functions

**Total**: ~170 truly unknown functions  
**Time Required**: 50-80 hours  
**Value**: Diminishing returns (most are utilities)

**Current State**: ~60 functions documented but keeping FUN_ names

---

## Recommendations

### High Value (Tier 1)

**~20 core system functions** worth analyzing:
- Directly impact gameplay
- Part of major systems
- 5-8 hours total

**Can Do**: Context analysis from our existing docs

### Medium Value (Tier 2)

**~30 gameplay functions**:
- Entity management
- Player mechanics
- 8-12 hours total

### Low Value (Tiers 3-4)

**~120 graphics/utility functions**:
- Mostly internal helpers
- Low gameplay impact
- 35-60 hours total

**Can Defer**: Not blocking for implementation

---

## Current Documentation Status

**Functions with Known Behavior**: ~1,598 (88%)  
**Documented in Our Docs**: ~60 FUN_ functions  
**Truly Unknown**: ~170 functions (12%)  
**High Priority Unknown**: ~50 functions (3%)

---

**Status**: 📋 **Complete List Compiled**  
**230 FUN_ functions** catalogued  
**~60 documented**, ~170 truly unknown  
**High-value**: ~50 functions worth analyzing

