/**
 * blb_accessors.h - Original Game BLB Header Accessors
 * 
 * These functions are direct ports of the verified decompiled functions
 * from the original Skullmonkeys game (PAL version SLES-01090).
 * 
 * Each function documents its original address and behavior.
 * DO NOT MODIFY unless updating to match Ghidra findings.
 */

#ifndef BLB_ACCESSORS_H
#define BLB_ACCESSORS_H

#include "../psx/types.h"

/* -----------------------------------------------------------------------------
 * BLB Header Layout Constants (PAL version)
 * 
 * The BLB header is the first 0x1000 bytes of GAME.BLB.
 * -------------------------------------------------------------------------- */

#define BLB_HEADER_SIZE         0x1000  /* 4096 bytes */
#define BLB_LEVEL_ENTRY_SIZE    0x70    /* 112 bytes per level */

/* Header offsets */
#define BLB_OFF_LEVEL_TABLE     0x000   /* 26 level entries */
#define BLB_OFF_MOVIE_TABLE     0xB60   /* 13 movie entries */
#define BLB_OFF_SECTOR_TABLE    0xCD0   /* 32 sector entries */
#define BLB_OFF_LEVEL_COUNT     0xF31   /* u8: number of levels */
#define BLB_OFF_MOVIE_COUNT     0xF32   /* u8: number of movies */
#define BLB_OFF_SECTOR_COUNT    0xF33   /* u8: sector table entries */
#define BLB_OFF_MODE_ARRAY      0xF36   /* Mode bytes for playback */
#define BLB_OFF_INDEX_ARRAY     0xF92   /* Level indices for playback */

/* Level entry offsets (within 0x70-byte entry) */
#define LEVEL_OFF_PRIMARY_SECTOR    0x00    /* u16: primary sector offset */
#define LEVEL_OFF_PRIMARY_COUNT     0x02    /* u16: primary sector count */
#define LEVEL_OFF_PRIMARY_SIZE      0x04    /* u32: primary buffer size */
#define LEVEL_OFF_ENTRY1_OFFSET     0x08    /* u32: Asset 601 offset in primary */
#define LEVEL_OFF_ASSET_INDEX       0x0C    /* u8: level asset index */
#define LEVEL_OFF_PASSWORD_FLAG     0x0D    /* u8: password entry flag */
#define LEVEL_OFF_STAGE_COUNT       0x0E    /* u16: number of stages (1-6) */
#define LEVEL_OFF_TERT_SIZES        0x10    /* u16[6]: tertiary data sizes >> 5 */
#define LEVEL_OFF_SEC_SECTOR        0x1E    /* u16[6]: secondary sector offsets */
#define LEVEL_OFF_SEC_COUNT         0x2C    /* u16[6]: secondary sector counts */
#define LEVEL_OFF_TERT_SECTOR       0x3A    /* u16[6]: tertiary sector offsets */
#define LEVEL_OFF_TERT_COUNT        0x48    /* u16[6]: tertiary sector counts */
#define LEVEL_OFF_LEVEL_ID          0x56    /* char[5]: 4-char ID + null */
#define LEVEL_OFF_LEVEL_NAME        0x5B    /* char[21]: level name */

/* -----------------------------------------------------------------------------
 * Level Entry Accessors
 * 
 * These read from the BLB header's level table (offset 0x000).
 * Each level entry is 0x70 (112) bytes.
 * -------------------------------------------------------------------------- */

/**
 * Helper: Get pointer to level entry in header
 */
static inline const u8* BLB_GetLevelEntry(const u8* header, u8 level_index) {
    if (!header || level_index >= 26) return NULL;
    return header + BLB_OFF_LEVEL_TABLE + ((u32)level_index * BLB_LEVEL_ENTRY_SIZE);
}

/**
 * Get level count from header
 * Original: GetLevelCount @ 0x8007a9b0 (reads ctx->header + 0xF31)
 */
static inline u8 BLB_Orig_GetLevelCount(const u8* header) {
    if (!header) return 0;
    return header[BLB_OFF_LEVEL_COUNT];
}

/**
 * Get level name string
 * Original: getLevelName @ 0x8007aa08
 * 
 * Returns pointer to 21-char null-terminated name at entry + 0x5B.
 */
static inline const char* BLB_Orig_GetLevelName(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return NULL;
    return (const char*)(entry + LEVEL_OFF_LEVEL_NAME);
}

/**
 * Get level ID code (4 characters)
 * 
 * Returns pointer to 5-byte string at entry + 0x56.
 */
static inline const char* BLB_Orig_GetLevelID(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return NULL;
    return (const char*)(entry + LEVEL_OFF_LEVEL_ID);
}

/**
 * Get level asset index
 * Original: GetLevelAssetIndex @ 0x8007a9c4
 * 
 * Returns u8 at entry + 0x0C.
 */
static inline u8 BLB_Orig_GetLevelAssetIndex(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return 0;
    return entry[LEVEL_OFF_ASSET_INDEX];
}

/**
 * Get stage count for a level
 * 
 * Returns u16 at entry + 0x0E.
 */
static inline u16 BLB_Orig_GetStageCount(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return 0;
    return *(const u16*)(entry + LEVEL_OFF_STAGE_COUNT);
}

/**
 * Get primary segment sector offset
 * 
 * Returns u16 at entry + 0x00.
 */
static inline u16 BLB_Orig_GetPrimarySector(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return 0;
    return *(const u16*)(entry + LEVEL_OFF_PRIMARY_SECTOR);
}

/**
 * Get primary segment sector count
 * 
 * Returns u16 at entry + 0x02.
 */
static inline u16 BLB_Orig_GetPrimarySectorCount(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return 0;
    return *(const u16*)(entry + LEVEL_OFF_PRIMARY_COUNT);
}

/**
 * Get primary buffer size
 * Original: GetPrimaryBufferSize @ 0x8007a5cc
 * 
 * Returns u32 at entry + 0x04.
 */
static inline u32 BLB_Orig_GetPrimaryBufferSize(const u8* header, u8 level_index) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry) return 0;
    return *(const u32*)(entry + LEVEL_OFF_PRIMARY_SIZE);
}

/**
 * Get secondary segment sector offset for a stage
 * 
 * Returns entry[0x1E + stage*2] (u16 array at offset 0x1E).
 */
static inline u16 BLB_Orig_GetSecondarySector(const u8* header, u8 level_index, u8 stage) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry || stage >= 6) return 0;
    return *(const u16*)(entry + LEVEL_OFF_SEC_SECTOR + stage * 2);
}

/**
 * Get secondary segment sector count for a stage
 * 
 * Returns entry[0x2C + stage*2] (u16 array at offset 0x2C).
 */
static inline u16 BLB_Orig_GetSecondarySectorCount(const u8* header, u8 level_index, u8 stage) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry || stage >= 6) return 0;
    return *(const u16*)(entry + LEVEL_OFF_SEC_COUNT + stage * 2);
}

/**
 * Get tertiary segment sector offset for a stage
 * 
 * Returns entry[0x3A + stage*2] (u16 array at offset 0x3A).
 */
static inline u16 BLB_Orig_GetTertiarySector(const u8* header, u8 level_index, u8 stage) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry || stage >= 6) return 0;
    return *(const u16*)(entry + LEVEL_OFF_TERT_SECTOR + stage * 2);
}

/**
 * Get tertiary segment sector count for a stage
 * 
 * Returns entry[0x48 + stage*2] (u16 array at offset 0x48).
 */
static inline u16 BLB_Orig_GetTertiarySectorCount(const u8* header, u8 level_index, u8 stage) {
    const u8* entry = BLB_GetLevelEntry(header, level_index);
    if (!entry || stage >= 6) return 0;
    return *(const u16*)(entry + LEVEL_OFF_TERT_COUNT + stage * 2);
}

/* -----------------------------------------------------------------------------
 * Segment TOC Access
 * 
 * Each segment starts with a TOC: u32 count, then count × 12-byte entries.
 * Entry format: { u32 asset_id, u32 size, u32 offset }
 * -------------------------------------------------------------------------- */

/**
 * Get segment TOC count
 * 
 * First u32 in segment is entry count.
 */
static inline u32 BLB_Orig_GetSegmentTOCCount(const u8* segment) {
    if (!segment) return 0;
    return *(const u32*)segment;
}

/**
 * Find asset in segment TOC
 * 
 * Searches for asset_id in segment's TOC entries.
 * Returns pointer to asset data, or NULL if not found.
 */
static inline const u8* BLB_Orig_FindAsset(const u8* segment, u32 asset_id, u32* out_size) {
    u32 count, i;
    const u8* toc;
    
    if (!segment) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    count = *(const u32*)segment;
    toc = segment + 4;  /* Skip count */
    
    for (i = 0; i < count; i++) {
        u32 id = *(const u32*)(toc + i * 12 + 0);
        if (id == asset_id) {
            u32 size = *(const u32*)(toc + i * 12 + 4);
            u32 offset = *(const u32*)(toc + i * 12 + 8);
            if (out_size) *out_size = size;
            return segment + offset;
        }
    }
    
    if (out_size) *out_size = 0;
    return NULL;
}

#endif /* BLB_ACCESSORS_H */
