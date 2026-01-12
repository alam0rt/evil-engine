/**
 * evil_engine.h - Public API for Evil Engine Library
 * 
 * This is the main public interface for the C99 BLB library.
 * It can be used by GDExtension, CLI tools, or any other application.
 * 
 * The library is organized in three layers:
 * - BLB file operations (reading/writing archive files)
 * - Level operations (loading/saving level data)
 * - Data accessors (querying level structures)
 */

#ifndef EVIL_ENGINE_H
#define EVIL_ENGINE_H

#include "psx/types.h"
#include "blb/blb.h"
#include "level/level.h"

/* -----------------------------------------------------------------------------
 * BLB File Operations (READ)
 * -------------------------------------------------------------------------- */

/**
 * Open a BLB archive file.
 * @param path      Path to GAME.BLB file
 * @param out_blb   Output BLB file handle (caller must free with EvilEngine_CloseBLB)
 * @return          0 on success, -1 on error
 */
int EvilEngine_OpenBLB(const char* path, BLBFile** out_blb);

/**
 * Close a BLB archive and free resources.
 * @param blb       BLB file handle to close
 */
void EvilEngine_CloseBLB(BLBFile* blb);

/**
 * Get number of levels in BLB archive.
 * @param blb       BLB file handle
 * @return          Number of levels (0-26)
 */
int EvilEngine_GetLevelCount(const BLBFile* blb);

/**
 * Get level name string.
 * @param blb       BLB file handle
 * @param index     Level index (0-based)
 * @return          Level name string, or NULL if invalid
 */
const char* EvilEngine_GetLevelName(const BLBFile* blb, int index);

/**
 * Get level ID code (4-character identifier like "SCIE").
 * @param blb       BLB file handle
 * @param index     Level index (0-based)
 * @return          Level ID string, or NULL if invalid
 */
const char* EvilEngine_GetLevelID(const BLBFile* blb, int index);

/* -----------------------------------------------------------------------------
 * Level Operations (READ)
 * -------------------------------------------------------------------------- */

/**
 * Load a level and stage from BLB.
 * @param blb           BLB file handle
 * @param level_index   Level index (0-25)
 * @param stage_index   Stage index (0-6)
 * @param out_level     Output level context (caller must free with EvilEngine_UnloadLevel)
 * @return              0 on success, -1 on error
 */
int EvilEngine_LoadLevel(const BLBFile* blb, int level_index, int stage_index, 
                         LevelContext** out_level);

/**
 * Unload a level and free resources.
 * @param level         Level context to unload
 */
void EvilEngine_UnloadLevel(LevelContext* level);

/* -----------------------------------------------------------------------------
 * Data Accessors (READ)
 * -------------------------------------------------------------------------- */

/**
 * Get tile header from loaded level.
 * @param level         Level context
 * @return              Pointer to tile header, or NULL if not loaded
 */
const TileHeader* EvilEngine_GetTileHeader(const LevelContext* level);

/**
 * Get layer entry by index.
 * @param level         Level context
 * @param layer_index   Layer index (0-based)
 * @return              Pointer to layer entry, or NULL if invalid
 */
const LayerEntry* EvilEngine_GetLayer(const LevelContext* level, int layer_index);

/**
 * Get layer count.
 * @param level         Level context
 * @return              Number of layers
 */
int EvilEngine_GetLayerCount(const LevelContext* level);

/**
 * Get entity definitions array.
 * @param level         Level context
 * @param out_count     Output: number of entities
 * @return              Pointer to entity array, or NULL if not loaded
 */
const EntityDef* EvilEngine_GetEntities(const LevelContext* level, int* out_count);

/**
 * Get tilemap data for a layer.
 * @param level         Level context
 * @param layer_index   Layer index
 * @return              Pointer to tilemap u16 array, or NULL if invalid
 */
const u16* EvilEngine_GetLayerTilemap(const LevelContext* level, int layer_index);

/**
 * Get tile pixel data (8bpp indexed).
 * @param level         Level context
 * @param tile_index    Tile index (0-based)
 * @param out_is_8x8    Output: true if 8x8 tile, false if 16x16
 * @return              Pointer to pixel data (128 or 256 bytes), or NULL if invalid
 */
const u8* EvilEngine_GetTilePixels(const LevelContext* level, int tile_index, 
                                   int* out_is_8x8);

/**
 * Get palette for a tile (PSX 15-bit RGB).
 * @param level         Level context
 * @param tile_index    Tile index
 * @return              Pointer to 256-color palette (512 bytes), or NULL if invalid
 */
const u16* EvilEngine_GetTilePalette(const LevelContext* level, int tile_index);

/**
 * Get total number of tiles in level.
 * @param level         Level context
 * @return              Total tile count (16x16 + 8x8 + extra)
 */
int EvilEngine_GetTotalTiles(const LevelContext* level);

/**
 * Get tile flags for a tile.
 * @param level         Level context
 * @param tile_index    Tile index (0-based)
 * @return              Tile flags byte (bit 0=semitrans, bit 1=8x8, bit 2=skip)
 */
int EvilEngine_GetTileFlags(const LevelContext* level, int tile_index);

/* -----------------------------------------------------------------------------
 * Palette Operations
 * -------------------------------------------------------------------------- */

/**
 * Get palette count from level.
 * @param level         Level context
 * @return              Number of palettes available
 */
int EvilEngine_GetPaletteCount(const LevelContext* level);

/**
 * Get a specific palette.
 * @param level         Level context
 * @param palette_index Palette index (0-based)
 * @param out_size      Output: palette size in bytes (typically 512)
 * @return              Pointer to palette data (PSX 15-bit RGB), or NULL if invalid
 */
const u16* EvilEngine_GetPalette(const LevelContext* level, int palette_index, int* out_size);

/**
 * Convert PSX 15-bit color to RGBA (0xAABBGGRR format).
 * @param psx_color     PSX 15-bit color value
 * @return              32-bit RGBA color
 */
unsigned int EvilEngine_PSXColorToRGBA(unsigned short psx_color);

/* -----------------------------------------------------------------------------
 * Sprite Operations
 * -------------------------------------------------------------------------- */

/**
 * Get sprite count from a segment.
 * @param segment_data  Pointer to sprite container (Asset 600)
 * @param out_count     Output: number of sprites
 * @return              0 on success, -1 on error
 */
int EvilEngine_GetSpriteCount(const unsigned char* segment_data, int* out_count);

/**
 * Get sprite data from container.
 * @param segment_data  Pointer to sprite container
 * @param sprite_index  Sprite index (0-based)
 * @param out_sprite_id Output: sprite ID
 * @param out_size      Output: sprite data size
 * @return              Pointer to sprite data, or NULL if invalid
 */
const unsigned char* EvilEngine_GetSprite(const unsigned char* segment_data, int sprite_index,
                                          unsigned int* out_sprite_id, int* out_size);

/**
 * Parse sprite header.
 * @param sprite_data   Pointer to sprite data
 * @param out_header    Output: header structure pointer
 * @return              0 on success, -1 on error
 */
int EvilEngine_ParseSpriteHeader(const unsigned char* sprite_data, void* out_header);

/**
 * Get sprite animation.
 * @param sprite_data   Pointer to sprite data
 * @param anim_index    Animation index (0-based)
 * @param out_anim      Output: animation structure pointer
 * @return              0 on success, -1 on error
 */
int EvilEngine_GetSpriteAnimation(const unsigned char* sprite_data, int anim_index, void* out_anim);

/**
 * Get sprite frame metadata.
 * @param sprite_data       Pointer to sprite data
 * @param frame_meta_offset Frame metadata base offset
 * @param frame_index       Frame index
 * @param out_frame         Output: frame structure pointer
 * @return                  0 on success, -1 on error
 */
int EvilEngine_GetSpriteFrameMetadata(const unsigned char* sprite_data, int frame_meta_offset,
                                      int frame_index, void* out_frame);

/**
 * Get sprite's embedded palette.
 * @param sprite_data   Pointer to sprite data
 * @param palette_offset Palette offset
 * @return              Pointer to 256-color palette (512 bytes), or NULL
 */
const unsigned short* EvilEngine_GetSpritePalette(const unsigned char* sprite_data, unsigned int palette_offset);

/* -----------------------------------------------------------------------------
 * Raw Asset Access
 * -------------------------------------------------------------------------- */

/**
 * Find and get raw asset data from a level segment.
 * @param blb           BLB file handle
 * @param level_index   Level index
 * @param stage_index   Stage index
 * @param segment_type  0=primary, 1=secondary, 2=tertiary
 * @param asset_id      Asset type ID
 * @param out_size      Output: asset size in bytes
 * @return              Pointer to asset data, or NULL if not found
 */
const unsigned char* EvilEngine_GetAssetData(const BLBFile* blb, int level_index, int stage_index,
                                             int segment_type, unsigned int asset_id, int* out_size);

/* -----------------------------------------------------------------------------
 * BLB File Operations (WRITE)
 * -------------------------------------------------------------------------- */

/**
 * Create a new BLB archive in memory.
 * @param level_count   Number of levels to allocate (1-26)
 * @param out_blb       Output BLB file handle (caller must free)
 * @return              0 on success, -1 on error
 */
int EvilEngine_CreateBLB(int level_count, BLBFile** out_blb);

/**
 * Set level metadata in BLB header.
 * @param blb           BLB file handle
 * @param level_index   Level index (0-based)
 * @param level_id      4-character level ID (e.g. "SCIE")
 * @param level_name    Level name (max 20 characters)
 * @param stage_count   Number of stages in this level (1-7)
 * @return              0 on success, -1 on error
 */
int EvilEngine_SetLevelMetadata(BLBFile* blb, int level_index,
                                const char* level_id, const char* level_name,
                                int stage_count);

/**
 * Write level segment data to BLB.
 * @param blb               BLB file handle
 * @param level_index       Level index (0-based)
 * @param stage_index       Stage index (0-based)
 * @param primary_data      Primary segment data
 * @param primary_size      Primary segment size in bytes
 * @param secondary_data    Secondary segment data (can be NULL)
 * @param secondary_size    Secondary segment size in bytes
 * @param tertiary_data     Tertiary segment data (can be NULL)
 * @param tertiary_size     Tertiary segment size in bytes
 * @return                  0 on success, -1 on error
 */
int EvilEngine_WriteLevelData(BLBFile* blb, int level_index, int stage_index,
                              const u8* primary_data, u32 primary_size,
                              const u8* secondary_data, u32 secondary_size,
                              const u8* tertiary_data, u32 tertiary_size);

/**
 * Finalize and write BLB to file.
 * @param blb           BLB file handle
 * @param path          Output file path
 * @return              0 on success, -1 on error
 */
int EvilEngine_SaveBLB(const BLBFile* blb, const char* path);

/* -----------------------------------------------------------------------------
 * Level Operations (WRITE)
 * -------------------------------------------------------------------------- */

/**
 * Build primary segment from level context.
 * Creates a properly formatted BLB primary segment with all assets.
 * Caller must free the returned buffer.
 * 
 * @param level         Level context with tile/layer/entity data
 * @param out_size      Output: segment size in bytes
 * @return              Allocated buffer with segment data, or NULL on error
 */
u8* EvilEngine_BuildPrimarySegment(const LevelContext* level, u32* out_size);

/**
 * Build secondary segment for a stage.
 * Caller must free the returned buffer.
 * 
 * @param level         Level context
 * @param stage         Stage index
 * @param out_size      Output: segment size in bytes
 * @return              Allocated buffer with segment data, or NULL on error
 */
u8* EvilEngine_BuildSecondarySegment(const LevelContext* level, int stage, u32* out_size);

/**
 * Build tertiary segment for a stage.
 * Caller must free the returned buffer.
 * 
 * @param level         Level context
 * @param stage         Stage index
 * @param out_size      Output: segment size in bytes
 * @return              Allocated buffer with segment data, or NULL on error
 */
u8* EvilEngine_BuildTertiarySegment(const LevelContext* level, int stage, u32* out_size);

#endif /* EVIL_ENGINE_H */
