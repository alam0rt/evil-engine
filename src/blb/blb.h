/**
 * blb.h - BLB Archive File Interface
 * 
 * Provides access to Skullmonkeys' GAME.BLB archive format.
 * Accessor patterns match the original decompiled game code.
 * 
 * VERIFIED FUNCTIONS are documented with their original addresses.
 * For 1:1 original game accessors, see blb_accessors.h.
 * 
 * EXPORT/WRITE FUNCTIONS are for the Godot addon only - they are
 * NOT part of the original game (marked as TOOL-ONLY).
 * 
 * BLB Header Layout (0x1000 bytes, PAL version SLES-01090):
 *   0x000 - 0xB5F  Level metadata table (26 entries × 0x70 bytes)
 *   0xB60 - 0xCC7  Movie table (13 entries × 0x1C bytes)  
 *   0xCD0 - 0xECF  Sector table (32 entries × 0x10 bytes)
 *   0xF31          Level count (u8)
 *   0xF32          Movie count (u8)
 * 
 * See docs/blb-data-format.md for complete specification.
 */

#ifndef BLB_H
#define BLB_H

#include "../psx/types.h"

/* -----------------------------------------------------------------------------
 * Constants (VERIFIED from Ghidra analysis)
 * -------------------------------------------------------------------------- */

#define BLB_HEADER_SIZE     0x1000      /* 4096 bytes */
#define BLB_SECTOR_SIZE     2048
#define BLB_LEVEL_ENTRY_SIZE 0x70       /* 112 bytes per level */
#define BLB_MAX_LEVELS      26
#define BLB_MAX_STAGES      7           /* Max stages per level */

/* Header offsets (PAL version) */
#define BLB_OFF_LEVEL_TABLE     0x000
#define BLB_OFF_MOVIE_TABLE     0xB60
#define BLB_OFF_SECTOR_TABLE    0xCD0
#define BLB_OFF_LEVEL_COUNT     0xF31
#define BLB_OFF_MOVIE_COUNT     0xF32
#define BLB_OFF_SECTOR_COUNT    0xF33

/* Level entry field offsets (within 0x70-byte entry) */
#define LEVEL_OFF_PRIMARY_SECTOR    0x00    /* u16 */
#define LEVEL_OFF_PRIMARY_COUNT     0x02    /* u16 */
#define LEVEL_OFF_PRIMARY_SIZE      0x04    /* u32 */
#define LEVEL_OFF_ENTRY1_OFFSET     0x08    /* u32 */
#define LEVEL_OFF_ASSET_INDEX       0x0C    /* u8 */
#define LEVEL_OFF_PASSWORD_FLAG     0x0D    /* u8 */
#define LEVEL_OFF_STAGE_COUNT       0x0E    /* u16 */
#define LEVEL_OFF_SEC_SECTOR        0x1E    /* u16[7] */
#define LEVEL_OFF_SEC_COUNT         0x2C    /* u16[7] */
#define LEVEL_OFF_TERT_SECTOR       0x3A    /* u16[7] */
#define LEVEL_OFF_TERT_COUNT        0x48    /* u16[7] */
#define LEVEL_OFF_LEVEL_ID          0x56    /* char[5] */
#define LEVEL_OFF_LEVEL_NAME        0x5B    /* char[21] */

/* Asset type IDs */
#define ASSET_TILE_HEADER       100     /* 0x064 */
#define ASSET_TILE_HEADER_101   101     /* 0x065 */
#define ASSET_TILEMAP_CONTAINER 200     /* 0x0C8 */
#define ASSET_LAYER_ENTRIES     201     /* 0x0C9 */
#define ASSET_TILE_PIXELS       300     /* 0x12C */
#define ASSET_PALETTE_INDICES   301     /* 0x12D */
#define ASSET_TILE_FLAGS        302     /* 0x12E */
#define ASSET_ANIMATED_TILES    303     /* 0x12F */
#define ASSET_PALETTE_CONTAINER 400     /* 0x190 */
#define ASSET_PALETTE_ANIM      401     /* 0x191 */
#define ASSET_TILE_ATTRS        500     /* 0x1F4 */
#define ASSET_ENTITIES          501     /* 0x1F5 */
#define ASSET_VRAM_RECTS        502     /* 0x1F6 */
#define ASSET_ANIM_OFFSETS      503     /* 0x1F7 */
#define ASSET_VEHICLE_DATA      504     /* 0x1F8 */
#define ASSET_GEOMETRY          600     /* 0x258 - container */
#define ASSET_AUDIO_SAMPLES     601     /* 0x259 - container */
#define ASSET_PALETTE           602     /* 0x25A - raw palette */
#define ASSET_SPU_SAMPLES       700     /* 0x2BC */

/* -----------------------------------------------------------------------------
 * TOC Entry (12 bytes)
 * -------------------------------------------------------------------------- */

typedef struct {
    u32 id;         /* Asset type ID */
    u32 size;       /* Data size in bytes */
    u32 offset;     /* Offset from segment start */
} TOCEntry;

/* -----------------------------------------------------------------------------
 * BLB File Handle
 * -------------------------------------------------------------------------- */

typedef struct {
    u8*     data;           /* Memory-mapped or loaded file data */
    u32     size;           /* Total file size */
    u8*     header;         /* Pointer to header (first 0x1000 bytes) */
    u8      level_count;    /* Number of levels */
    u8      movie_count;    /* Number of movies */
    u8      sector_count;   /* Number of sector entries */
    u8      is_jp;          /* True if JP version (different offsets) */
} BLBFile;

/* -----------------------------------------------------------------------------
 * BLB File Operations
 * -------------------------------------------------------------------------- */

/**
 * Open a BLB file and parse the header.
 * @param path      Path to GAME.BLB file
 * @param blb       Output BLB file handle
 * @return          0 on success, -1 on error
 */
int BLB_Open(const char* path, BLBFile* blb);

/**
 * Open a BLB file from memory buffer.
 * @param data      Pointer to BLB data in memory
 * @param size      Size of data in bytes
 * @param blb       Output BLB file handle
 * @return          0 on success, -1 on error
 */
int BLB_OpenMem(const u8* data, u32 size, BLBFile* blb);

/**
 * Close a BLB file and free resources.
 */
void BLB_Close(BLBFile* blb);

/* -----------------------------------------------------------------------------
 * Header Accessors (match original decompiled patterns)
 * -------------------------------------------------------------------------- */

/**
 * Get total number of levels.
 * Original: GetLevelCount (reads header + 0xF31)
 */
u8 BLB_GetLevelCount(const BLBFile* blb);

/**
 * Get level name string.
 * Original: getLevelName (returns header + (index * 0x70) + 0x5B)
 */
const char* BLB_GetLevelName(const BLBFile* blb, u8 level_index);

/**
 * Get level 4-character ID code.
 * Returns pointer to 5-byte string (4 chars + null).
 */
const char* BLB_GetLevelID(const BLBFile* blb, u8 level_index);

/**
 * Get level asset index.
 * Original: GetLevelAssetIndex (reads level[index] + 0x0C)
 */
u8 BLB_GetLevelAssetIndex(const BLBFile* blb, u8 level_index);

/**
 * Get number of stages in a level.
 */
u16 BLB_GetStageCount(const BLBFile* blb, u8 level_index);

/**
 * Get primary segment sector offset.
 */
u16 BLB_GetPrimarySectorOffset(const BLBFile* blb, u8 level_index);

/**
 * Get primary segment sector count.
 */
u16 BLB_GetPrimarySectorCount(const BLBFile* blb, u8 level_index);

/**
 * Get secondary segment sector offset for a stage.
 */
u16 BLB_GetSecondarySectorOffset(const BLBFile* blb, u8 level_index, u8 stage);

/**
 * Get secondary segment sector count for a stage.
 */
u16 BLB_GetSecondarySectorCount(const BLBFile* blb, u8 level_index, u8 stage);

/**
 * Get tertiary segment sector offset for a stage.
 */
u16 BLB_GetTertiarySectorOffset(const BLBFile* blb, u8 level_index, u8 stage);

/**
 * Get tertiary segment sector count for a stage.
 */
u16 BLB_GetTertiarySectorCount(const BLBFile* blb, u8 level_index, u8 stage);

/* -----------------------------------------------------------------------------
 * Segment/Asset Access
 * -------------------------------------------------------------------------- */

/**
 * Get pointer to raw sector data.
 * @param sector_offset     Sector number from level entry
 * @return                  Pointer to data at that sector
 */
const u8* BLB_GetSectorData(const BLBFile* blb, u16 sector_offset);

/**
 * Read segment TOC at given sector location.
 * @param blb               BLB file handle
 * @param sector_offset     Starting sector
 * @param out_count         Output: number of TOC entries
 * @return                  Pointer to first TOCEntry, or NULL on error
 */
const TOCEntry* BLB_GetSegmentTOC(const BLBFile* blb, u16 sector_offset, u32* out_count);

/**
 * Find asset in a segment TOC by type ID.
 * @param blb               BLB file handle
 * @param segment_start     Pointer to start of segment data
 * @param asset_id          Asset type ID to find (e.g., ASSET_TILE_HEADER)
 * @param out_size          Output: asset size in bytes (optional, can be NULL)
 * @return                  Pointer to asset data, or NULL if not found
 */
const u8* BLB_FindAsset(const BLBFile* blb, const u8* segment_start, 
                        u32 asset_id, u32* out_size);

/* =============================================================================
 * TOOL-ONLY CODE BELOW - NOT PART OF ORIGINAL GAME
 * 
 * The following functions are for the Godot addon / BLB export tools.
 * They have no equivalent in the original Skullmonkeys binary.
 * ============================================================================= */

/* -----------------------------------------------------------------------------
 * BLB File Write Operations (TOOL-ONLY)
 * -------------------------------------------------------------------------- */

/**
 * Create a new BLB file in memory for writing.
 * The file is allocated with space for the specified number of levels.
 * 
 * TOOL-ONLY: Not present in original game.
 * 
 * @param level_count   Number of levels to allocate (1-26)
 * @return              BLB file handle, or NULL on error
 */
BLBFile* BLB_Create(u8 level_count);

/**
 * Set level metadata in BLB header.
 * This must be called before writing level data.
 * 
 * TOOL-ONLY: Not present in original game.
 * 
 * @param blb           BLB file handle
 * @param level_index   Level index (0-based)
 * @param level_id      4-character level ID (e.g., "SCIE")
 * @param level_name    Level name (max 20 chars)
 * @param stage_count   Number of stages (1-7)
 * @return              0 on success, -1 on error
 */
int BLB_SetLevelMetadata(BLBFile* blb, u8 level_index, 
                         const char* level_id, const char* level_name,
                         u16 stage_count);

/**
 * Write segment data to BLB for a specific level and stage.
 * The data will be written to appropriate sectors and the header updated.
 * 
 * TOOL-ONLY: Not present in original game.
 * 
 * @param blb               BLB file handle
 * @param level_index       Level index (0-based)
 * @param stage_index       Stage index (0-based, 0 = primary)
 * @param segment_data      Segment data buffer
 * @param segment_size      Size of segment data in bytes
 * @param segment_type      0=primary, 1=secondary, 2=tertiary
 * @return                  0 on success, -1 on error
 */
int BLB_WriteSegment(BLBFile* blb, u8 level_index, u8 stage_index,
                     const u8* segment_data, u32 segment_size,
                     u8 segment_type);

/**
 * Finalize and write BLB to file.
 * This writes the complete BLB archive to disk.
 * 
 * @param blb           BLB file handle
 * @param path          Output file path
 * @return              0 on success, -1 on error
 */
int BLB_WriteToFile(const BLBFile* blb, const char* path);

/* -----------------------------------------------------------------------------
 * Segment Building Helpers
 * -------------------------------------------------------------------------- */

/**
 * Helper structure for building segment TOCs.
 */
typedef struct {
    u32 asset_count;
    u32 capacity;
    TOCEntry* entries;
    u8* data;
    u32 data_size;
    u32 data_capacity;
} SegmentBuilder;

/**
 * Initialize a segment builder.
 * @param builder       Segment builder to initialize
 * @return              0 on success, -1 on error
 */
int BLB_SegmentBuilder_Init(SegmentBuilder* builder);

/**
 * Add an asset to the segment builder.
 * @param builder       Segment builder
 * @param asset_id      Asset type ID
 * @param data          Asset data
 * @param size          Asset data size
 * @return              0 on success, -1 on error
 */
int BLB_SegmentBuilder_AddAsset(SegmentBuilder* builder, u32 asset_id,
                                const u8* data, u32 size);

/**
 * Finalize the segment and get the output buffer.
 * Caller must free the returned buffer.
 * 
 * @param builder       Segment builder
 * @param out_size      Output: total segment size
 * @return              Allocated segment data, or NULL on error
 */
u8* BLB_SegmentBuilder_Finalize(SegmentBuilder* builder, u32* out_size);

/**
 * Free segment builder resources.
 * @param builder       Segment builder to free
 */
void BLB_SegmentBuilder_Free(SegmentBuilder* builder);

#endif /* BLB_H */
