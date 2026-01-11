/**
 * level_accessors.h - Original Game Level Data Accessors
 * 
 * These functions are direct ports of the verified decompiled functions
 * from the original Skullmonkeys game (PAL version SLES-01090).
 * 
 * Each function documents its original address and behavior.
 * DO NOT MODIFY unless updating to match Ghidra findings.
 * 
 * The LevelDataContext structure in the original game is an array of
 * 23 32-bit words (92 bytes minimum, up to 128 bytes with padding).
 * The layout uses integer offsets, not named fields.
 */

#ifndef LEVEL_ACCESSORS_H
#define LEVEL_ACCESSORS_H

#include "../psx/types.h"

/* -----------------------------------------------------------------------------
 * Original LevelDataContext Layout (from Ghidra)
 * 
 * The original game stores this at GameState + 0x84 (0x8009DCC4 in PAL).
 * It's accessed as an array of u32 pointers/values.
 * 
 * Index  Offset  Asset ID  Description
 * -----  ------  --------  -----------
 * [0]    0x00    -         Current sub-block index (0 or 1)
 * [1]    0x04    100       TileHeader pointer (Asset 100)
 * [2]    0x08    101       Asset 101 pointer (optional, 12 bytes)
 * [3]    0x0C    200       TilemapContainer pointer (Asset 200)
 * [4]    0x10    201       LayerEntries pointer (Asset 201)
 * [5]    0x14    300       TilePixels pointer (Asset 300)
 * [6]    0x18    301       PaletteIndices pointer (Asset 301)
 * [7]    0x1C    302       TileFlags pointer (Asset 302)
 * [8]    0x20    400       PaletteContainer pointer (Asset 400)
 * [9]    0x24    401       PaletteAnimData pointer (Asset 401)
 * [10]   0x28    303       AnimatedTileData pointer (Asset 303)
 * [11]   0x2C    500       TileAttributes pointer (Asset 500)
 * [12]   0x30    503       AnimOffsets pointer (Asset 503)
 * [13]   0x34    504       VehicleData pointer (Asset 504)
 * [14]   0x38    501       EntityData pointer (Asset 501)
 * [15]   0x3C    502       VRAMRects pointer (Asset 502)
 * [16]   0x40    600       GeometryContainer pointer (Asset 600)
 * [17]   0x44    600       GeometrySize (u32)
 * [18]   0x48    601       AudioSamples pointer (Asset 601)
 * [19]   0x4C    601       AudioSize (u32)
 * [20]   0x50    602       PaletteRaw pointer (Asset 602)
 * [21]   0x54    700       SPUSamples pointer (Asset 700)
 * [22]   0x58    700       SPUSamplesSize (u32)
 * [23]   0x5C    -         BLB Header pointer
 * [24]   0x60    -         Playback state byte offset
 * [25]   0x64    -         Loader callback function
 * [26]   0x68    -         Primary buffer pointer
 * [27]   0x6C    -         Secondary buffer pointer
 * -------------------------------------------------------------------------- */

/* Forward declare the opaque context type */
typedef struct OriginalLevelContext OriginalLevelContext;

/* Structure matching the original game's 92+ byte context */
struct OriginalLevelContext {
    u32 sub_block_index;        /* [0]  0x00 - Current sub-block (0 or 1) */
    u32 tile_header;            /* [1]  0x04 - Asset 100 pointer */
    u32 asset_101;              /* [2]  0x08 - Asset 101 pointer */
    u32 tilemap_container;      /* [3]  0x0C - Asset 200 pointer */
    u32 layer_entries;          /* [4]  0x10 - Asset 201 pointer */
    u32 tile_pixels;            /* [5]  0x14 - Asset 300 pointer */
    u32 palette_indices;        /* [6]  0x18 - Asset 301 pointer */
    u32 tile_flags;             /* [7]  0x1C - Asset 302 pointer */
    u32 palette_container;      /* [8]  0x20 - Asset 400 pointer */
    u32 palette_anim;           /* [9]  0x24 - Asset 401 pointer */
    u32 animated_tiles;         /* [10] 0x28 - Asset 303 pointer */
    u32 tile_attributes;        /* [11] 0x2C - Asset 500 pointer */
    u32 anim_offsets;           /* [12] 0x30 - Asset 503 pointer */
    u32 vehicle_data;           /* [13] 0x34 - Asset 504 pointer */
    u32 entity_data;            /* [14] 0x38 - Asset 501 pointer */
    u32 vram_rects;             /* [15] 0x3C - Asset 502 pointer */
    u32 geometry;               /* [16] 0x40 - Asset 600 pointer */
    u32 geometry_size;          /* [17] 0x44 - Asset 600 size */
    u32 audio_samples;          /* [18] 0x48 - Asset 601 pointer */
    u32 audio_size;             /* [19] 0x4C - Asset 601 size */
    u32 palette_raw;            /* [20] 0x50 - Asset 602 pointer */
    u32 spu_samples;            /* [21] 0x54 - Asset 700 pointer */
    u32 spu_size;               /* [22] 0x58 - Asset 700 size */
    u32 blb_header;             /* [23] 0x5C - BLB header pointer */
    u8  playback_offset;        /* [24] 0x60 - Playback state index */
    u8  _pad_61[3];
    u32 loader_callback;        /* [25] 0x64 - Sector loader function */
    u32 primary_buffer;         /* [26] 0x68 - Primary data buffer */
    u32 secondary_buffer;       /* [27] 0x6C - Secondary data buffer */
};

/* -----------------------------------------------------------------------------
 * Tile Header Accessors
 * These read from Asset 100 (TileHeader, 36 bytes)
 * -------------------------------------------------------------------------- */

/**
 * GetTileHeaderPtr - Returns pointer to Asset 100 (TileHeader)
 * Original: 0x8007b4b8
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Pointer to TileHeader (Asset 100)
 */
static inline const u8* Orig_GetTileHeaderPtr(const OriginalLevelContext* ctx) {
    /* Original: return *(u32*)(ctx + 4); */
    return (const u8*)(uintptr_t)ctx->tile_header;
}

/**
 * GetTotalTileCount - Sum of 16x16 + 8x8 + extra tile counts
 * Original: 0x8007b53c
 * 
 * Reads TileHeader offsets 0x10, 0x12, 0x14.
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Total number of tiles
 */
static inline u32 Orig_GetTotalTileCount(const OriginalLevelContext* ctx) {
    /* Original:
     * iVar1 = *(int*)(ctx + 4);
     * return *(u16*)(iVar1 + 0x10) + *(u16*)(iVar1 + 0x12) + *(u16*)(iVar1 + 0x14);
     */
    const u8* hdr = Orig_GetTileHeaderPtr(ctx);
    if (!hdr) return 0;
    u16 n16x16 = *(const u16*)(hdr + 0x10);
    u16 n8x8   = *(const u16*)(hdr + 0x12);
    u16 extra  = *(const u16*)(hdr + 0x14);
    return (u32)n16x16 + (u32)n8x8 + (u32)extra;
}

/**
 * GetEntityCount - Returns entity count from TileHeader
 * Original: 0x8007b7a8
 * 
 * Reads TileHeader offset 0x1E.
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Number of entities in Asset 501
 */
static inline u16 Orig_GetEntityCount(const OriginalLevelContext* ctx) {
    /* Original: return *(u16*)(*(int*)(ctx + 4) + 0x1E); */
    const u8* hdr = Orig_GetTileHeaderPtr(ctx);
    if (!hdr) return 0;
    return *(const u16*)(hdr + 0x1E);
}

/* -----------------------------------------------------------------------------
 * Tile Data Accessors
 * -------------------------------------------------------------------------- */

/**
 * GetTileSizeFlags - Returns pointer to Asset 302 (tile flags)
 * Original: 0x8007b6bc
 * 
 * Each byte: bit0=semi-trans, bit1=8x8, bit2=skip
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Pointer to tile flags array
 */
static inline const u8* Orig_GetTileSizeFlags(const OriginalLevelContext* ctx) {
    /* Original: return *(u32*)(ctx + 0x1C); */
    return (const u8*)(uintptr_t)ctx->tile_flags;
}

/**
 * GetPaletteIndices - Returns pointer to Asset 301 (palette per tile)
 * Original: 0x8007b6b0
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Pointer to palette index array (1 byte per tile)
 */
static inline const u8* Orig_GetPaletteIndices(const OriginalLevelContext* ctx) {
    /* Original: return *(u32*)(ctx + 0x18); */
    return (const u8*)(uintptr_t)ctx->palette_indices;
}

/* -----------------------------------------------------------------------------
 * Palette Accessors
 * -------------------------------------------------------------------------- */

/**
 * GetPaletteGroupCount - Returns number of palettes in container
 * Original: 0x8007b4d0
 * 
 * Reads first u32 from Asset 400 (palette container).
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Number of 256-color palettes
 */
static inline u8 Orig_GetPaletteGroupCount(const OriginalLevelContext* ctx) {
    /* Original:
     * if (*(u8**)(ctx + 0x20) == NULL) return 0;
     * return **(u8**)(ctx + 0x20);
     */
    const u8* container = (const u8*)(uintptr_t)ctx->palette_container;
    if (!container) return 0;
    return container[0];
}

/**
 * GetPaletteDataPtr - Returns pointer to a specific palette
 * Original: 0x8007b4f8
 * 
 * Uses sub-TOC at Asset 400. Each entry is 12 bytes, offset at +8.
 * 
 * @param ctx           LevelDataContext pointer
 * @param palette_idx   Palette index (0-based)
 * @return              Pointer to 256-color palette (512 bytes)
 */
static inline const u16* Orig_GetPaletteDataPtr(const OriginalLevelContext* ctx, u8 palette_idx) {
    /* Original:
     * iVar1 = *(int*)(ctx + 0x20);
     * if (iVar1 == 0) return 0;
     * return iVar1 + *(int*)(iVar1 + (palette_idx & 0xFF) * 0x0C + 0x0C);
     */
    const u8* container = (const u8*)(uintptr_t)ctx->palette_container;
    if (!container) return NULL;
    
    /* Sub-TOC: first entry at offset 4 (after count), 12 bytes each */
    /* Offset field is at +8 within each 12-byte entry */
    /* Note: Original uses +0x0C which skips the count u32 and indexes entries */
    u32 entry_offset = 4 + ((u32)palette_idx * 12);
    u32 data_offset = *(const u32*)(container + entry_offset + 8);
    
    return (const u16*)(container + data_offset);
}

/* -----------------------------------------------------------------------------
 * Tilemap Accessors
 * -------------------------------------------------------------------------- */

/**
 * GetTilemapDataPtr - Returns pointer to tilemap for a layer
 * Original: 0x8007b6dc
 * 
 * Uses sub-TOC at Asset 200. Each entry is 12 bytes, offset at +8.
 * 
 * @param ctx         LevelDataContext pointer
 * @param layer_idx   Layer index (0-based)
 * @return            Pointer to u16 tilemap array
 */
static inline const u16* Orig_GetTilemapDataPtr(const OriginalLevelContext* ctx, u16 layer_idx) {
    /* Original:
     * return *(int*)(ctx + 0x0C) + 
     *        *(int*)(*(int*)(ctx + 0x0C) + (layer_idx & 0xFFFF) * 0x0C + 0x0C);
     */
    const u8* container = (const u8*)(uintptr_t)ctx->tilemap_container;
    if (!container) return NULL;
    
    u32 entry_offset = 4 + ((u32)layer_idx * 12);
    u32 data_offset = *(const u32*)(container + entry_offset + 8);
    
    return (const u16*)(container + data_offset);
}

/* -----------------------------------------------------------------------------
 * Entity Accessors
 * -------------------------------------------------------------------------- */

/**
 * GetEntityDataPtr - Returns pointer to Asset 501 (entity definitions)
 * Original: 0x8007b7bc
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Pointer to entity definition array (24 bytes each)
 */
static inline const u8* Orig_GetEntityDataPtr(const OriginalLevelContext* ctx) {
    /* Original: return *(u32*)(ctx + 0x38); */
    return (const u8*)(uintptr_t)ctx->entity_data;
}

/* -----------------------------------------------------------------------------
 * Animation Accessors
 * -------------------------------------------------------------------------- */

/**
 * GetAnimatedTileData - Returns animation data for an animated tile
 * Original: 0x8007b658
 * 
 * Only returns data if tile_index > (n_16x16 + n_8x8) and anim data exists.
 * Animation entries are 4 bytes each.
 * 
 * @param ctx         LevelDataContext pointer
 * @param tile_index  Tile index (1-based from tilemap)
 * @return            Animation entry (4 bytes) or 0 if not animated
 */
static inline u32 Orig_GetAnimatedTileData(const OriginalLevelContext* ctx, u32 tile_index) {
    /* Original:
     * uVar1 = (*(u16*)(*(int*)(ctx + 4) + 0x10) + *(u16*)(*(int*)(ctx + 4) + 0x12)) & 0xFFFF;
     * if (uVar1 <= tile_index - 1) {
     *     if (*(int*)(ctx + 0x28) != 0) {
     *         return *(u32*)(((tile_index - 1) - uVar1) * 4 + *(int*)(ctx + 0x28));
     *     }
     * }
     * return 0;
     */
    const u8* hdr = Orig_GetTileHeaderPtr(ctx);
    if (!hdr) return 0;
    
    u32 static_count = ((u32)*(const u16*)(hdr + 0x10) + (u32)*(const u16*)(hdr + 0x12)) & 0xFFFF;
    
    if (static_count <= tile_index - 1) {
        const u8* anim_data = (const u8*)(uintptr_t)ctx->animated_tiles;
        if (anim_data) {
            u32 anim_index = (tile_index - 1) - static_count;
            return *(const u32*)(anim_data + anim_index * 4);
        }
    }
    return 0;
}

/**
 * GetPaletteAnimData - Returns pointer to Asset 401 (palette animation)
 * Original: 0x8007b530
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Pointer to palette animation config
 */
static inline const u8* Orig_GetPaletteAnimData(const OriginalLevelContext* ctx) {
    /* Original: return *(u32*)(ctx + 0x24); */
    return (const u8*)(uintptr_t)ctx->palette_anim;
}

/* -----------------------------------------------------------------------------
 * BLB Header Accessors
 * -------------------------------------------------------------------------- */

/**
 * GetLevelCount - Returns number of levels from BLB header
 * Original: 0x8007a9b0
 * 
 * Reads header offset 0xF31.
 * 
 * @param ctx  LevelDataContext pointer
 * @return     Number of levels (typically 26)
 */
static inline u8 Orig_GetLevelCount(const OriginalLevelContext* ctx) {
    /* Original: return *(u8*)(*(int*)(ctx + 0x5C) + 0xF31); */
    const u8* header = (const u8*)(uintptr_t)ctx->blb_header;
    if (!header) return 0;
    return header[0xF31];
}

/**
 * getLevelName - Returns pointer to level name string
 * Original: 0x8007aa08
 * 
 * LevelEntry is 0x70 bytes, name is at offset 0x5B (21 chars max).
 * 
 * @param ctx         LevelDataContext pointer
 * @param level_idx   Level table index (0-25)
 * @return            Pointer to null-terminated level name
 */
static inline const char* Orig_getLevelName(const OriginalLevelContext* ctx, u8 level_idx) {
    /* Original: return *(int*)(ctx + 0x5C) + (level_idx & 0xFF) * 0x70 + 0x5B; */
    const u8* header = (const u8*)(uintptr_t)ctx->blb_header;
    if (!header) return NULL;
    return (const char*)(header + (u32)level_idx * 0x70 + 0x5B);
}

/**
 * GetLevelAssetIndex - Returns level's asset index
 * Original: 0x8007a9c4
 * 
 * LevelEntry offset 0x0C contains the asset index.
 * 
 * @param ctx         LevelDataContext pointer
 * @param level_idx   Level table index (0-25)
 * @return            Level asset index (u8)
 */
static inline u8 Orig_GetLevelAssetIndex(const OriginalLevelContext* ctx, u8 level_idx) {
    /* Original: return *(u8*)(*(int*)(ctx + 0x5C) + (level_idx & 0xFF) * 0x70 + 0x0C); */
    const u8* header = (const u8*)(uintptr_t)ctx->blb_header;
    if (!header) return 0;
    return header[(u32)level_idx * 0x70 + 0x0C];
}

#endif /* LEVEL_ACCESSORS_H */
