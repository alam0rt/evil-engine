/**
 * level_export.h - Level Data Export/Packing Functions
 * 
 * TOOL-ONLY CODE - NOT PART OF ORIGINAL GAME
 * 
 * These functions are for the Godot addon/external tools to export
 * modified level data back to BLB format. They have no equivalent
 * in the original game binary.
 * 
 * Original game functions are in:
 *   - level/level_accessors.h (verified game accessors)
 *   - blb/blb_accessors.h (verified BLB header accessors)
 */

#ifndef LEVEL_EXPORT_H
#define LEVEL_EXPORT_H

#include "../psx/types.h"
#include "level.h"

/* -----------------------------------------------------------------------------
 * Data Packing Functions
 * 
 * These convert in-memory structures to BLB-compatible binary format.
 * All return malloc'd buffers that the caller must free.
 * -------------------------------------------------------------------------- */

/**
 * Pack tilemap data into BLB Asset 200 format.
 * 
 * @param tilemap_data  Array of u16 tile indices
 * @param width         Tilemap width in tiles
 * @param height        Tilemap height in tiles
 * @param out_size      Output: size of packed data
 * @return              Allocated buffer (caller must free)
 */
u8* Level_PackTilemap(const u16* tilemap_data, u32 width, u32 height, u32* out_size);

/**
 * Pack layer entries into BLB Asset 201 format.
 * 
 * @param layers        Array of LayerEntry structures
 * @param count         Number of layer entries
 * @param out_size      Output: size of packed data
 * @return              Allocated buffer (caller must free)
 */
u8* Level_PackLayers(const LayerEntry* layers, u32 count, u32* out_size);

/**
 * Pack entity definitions into BLB Asset 501 format.
 * 
 * @param entities      Array of EntityDef structures
 * @param count         Number of entities
 * @param out_size      Output: size of packed data
 * @return              Allocated buffer (caller must free)
 */
u8* Level_PackEntities(const EntityDef* entities, u32 count, u32* out_size);

/**
 * Pack tile pixel data into BLB Asset 300 format.
 * 
 * @param pixels        Raw 8bpp pixel data
 * @param tile_count    Number of tiles
 * @param out_size      Output: size of packed data
 * @return              Allocated buffer (caller must free)
 */
u8* Level_PackTilePixels(const u8* pixels, u32 tile_count, u32* out_size);

/**
 * Pack palette data into BLB Asset 400 format.
 * 
 * @param palettes      Array of 256-color palettes (PSX 15-bit)
 * @param palette_count Number of palettes
 * @param out_size      Output: size of packed data
 * @return              Allocated buffer (caller must free)
 */
u8* Level_PackPalettes(const u16* palettes, u32 palette_count, u32* out_size);

/**
 * Pack tile header into BLB Asset 100 format.
 * 
 * @param header        TileHeader structure
 * @param out_size      Output: size of packed data (36 bytes)
 * @return              Allocated buffer (caller must free)
 */
u8* Level_PackTileHeader(const TileHeader* header, u32* out_size);

/* -----------------------------------------------------------------------------
 * Segment Building Functions
 * 
 * These build complete BLB segments with TOC and asset data.
 * -------------------------------------------------------------------------- */

/**
 * Build primary segment from level context.
 * 
 * @param ctx           Level context with loaded data
 * @param out_size      Output: segment size in bytes
 * @return              Allocated segment buffer (caller must free)
 */
u8* Level_BuildPrimarySegment(const LevelContext* ctx, u32* out_size);

/**
 * Build secondary segment from level context.
 * 
 * @param ctx           Level context with loaded data
 * @param stage         Stage index (0-5)
 * @param out_size      Output: segment size in bytes
 * @return              Allocated segment buffer (caller must free)
 */
u8* Level_BuildSecondarySegment(const LevelContext* ctx, u8 stage, u32* out_size);

/**
 * Build tertiary segment from level context.
 * 
 * @param ctx           Level context with loaded data
 * @param stage         Stage index (0-5)
 * @param out_size      Output: segment size in bytes
 * @return              Allocated segment buffer (caller must free)
 */
u8* Level_BuildTertiarySegment(const LevelContext* ctx, u8 stage, u32* out_size);

#endif /* LEVEL_EXPORT_H */
