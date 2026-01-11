/**
 * render.h - Tile and Sprite Rendering Accessors
 * 
 * Authentic accessor functions matching original decompiled patterns.
 * These functions provide access to tile pixel data, palettes, and
 * tilemaps for rendering.
 * 
 * Based on Ghidra analysis:
 * - GetTileHeaderPtr     @ 0x8007b4b8
 * - GetTotalTileCount    @ 0x8007b53c
 * - CopyTilePixelData    @ 0x8007b588
 * - GetTileSizeFlags     @ 0x8007b6bc
 * - GetTilemapDataPtr    @ 0x8007b6dc
 * - GetPaletteDataPtr    @ 0x8007b4f8
 * - GetPaletteIndices    @ 0x8007b6b0
 */

#ifndef RENDER_H
#define RENDER_H

#include "../psx/types.h"
#include "../level/level.h"

/* -----------------------------------------------------------------------------
 * Tile Header Access
 * Based on GetTileHeaderPtr @ 0x8007b4b8: return *(ctx + 4)
 * -------------------------------------------------------------------------- */

/**
 * Get pointer to tile header (Asset 100).
 * Original: return *(undefined4 *)(param_1 + 4);
 */
static inline const TileHeader* GetTileHeaderPtr(const LevelContext* ctx) {
    return ctx->tile_header;  /* ctx + 0x04 in original layout */
}

/* -----------------------------------------------------------------------------
 * Tile Count
 * Based on GetTotalTileCount @ 0x8007b53c
 * Returns: count_16x16 + count_8x8_a + count_8x8_b
 * -------------------------------------------------------------------------- */

/**
 * Get total tile count.
 * Original: header[0x10] + header[0x12] + header[0x14]
 */
static inline u32 GetTotalTileCount(const LevelContext* ctx) {
    const TileHeader* hdr = ctx->tile_header;
    if (!hdr) return 0;
    return (u32)hdr->count_16x16 + (u32)hdr->count_8x8 + (u32)hdr->count_extra;
}

/* -----------------------------------------------------------------------------
 * Tile Size Flags
 * Based on GetTileSizeFlags @ 0x8007b6bc: return *(ctx + 0x1C)
 * Each byte: bit0=semi-transparent, bit1=8x8 size, bit2=skip
 * -------------------------------------------------------------------------- */

#define TILE_FLAG_SEMITRANS  0x01
#define TILE_FLAG_8X8        0x02
#define TILE_FLAG_SKIP       0x04

/**
 * Get tile flags array pointer.
 * Original: return *(undefined4 *)(param_1 + 0x1c);
 */
static inline const u8* GetTileSizeFlags(const LevelContext* ctx) {
    return ctx->tile_flags;  /* Asset 302 */
}

/**
 * Check if tile is 8x8 (vs 16x16).
 */
static inline int IsTile8x8(const LevelContext* ctx, u16 tile_index) {
    if (!ctx->tile_flags) return 0;
    return (ctx->tile_flags[tile_index] & TILE_FLAG_8X8) != 0;
}

/* -----------------------------------------------------------------------------
 * Palette Access
 * Based on GetPaletteIndices @ 0x8007b6b0: return *(ctx + 0x18)
 * Based on GetPaletteDataPtr @ 0x8007b4f8
 * -------------------------------------------------------------------------- */

/**
 * Get palette indices array (one byte per tile).
 * Original: return *(undefined4 *)(param_1 + 0x18);
 */
static inline const u8* GetPaletteIndices(const LevelContext* ctx) {
    return ctx->palette_indices;  /* Asset 301 */
}

/**
 * Get palette data pointer for specific palette index.
 * Original pattern:
 *   iVar1 = *(int *)(param_1 + 0x20);  // palette container
 *   if (iVar1 == 0) return 0;
 *   return iVar1 + *(int *)(iVar1 + (index & 0xff) * 0xc + 0xc);
 * 
 * Returns pointer to 256 x 16-bit PSX colors (512 bytes).
 */
const u16* GetPaletteDataPtr(const LevelContext* ctx, u8 palette_index);

/* -----------------------------------------------------------------------------
 * Tilemap Access
 * Based on GetTilemapDataPtr @ 0x8007b6dc
 * -------------------------------------------------------------------------- */

/**
 * Get tilemap data pointer for a layer.
 * Original pattern:
 *   container = *(int *)(param_1 + 0xc);
 *   return container + *(int *)(container + layer * 0xc + 0xc);
 * 
 * Returns array of u16 values (width * height).
 * Each u16: bits 0-10 = tile index (1-based, 0=transparent)
 */
const u16* GetTilemapDataPtr(const LevelContext* ctx, u32 layer_index);

/* -----------------------------------------------------------------------------
 * Tile Pixel Data Access
 * Based on CopyTilePixelData @ 0x8007b588
 * -------------------------------------------------------------------------- */

/**
 * Get raw pointer to tile pixel data.
 * 
 * Layout in memory:
 *   - 16x16 tiles: 256 bytes each (16 rows * 16 bytes)
 *   - 8x8 tiles: 128 bytes each (8 rows * 16 bytes, only first 8 cols used)
 *   
 * Formula from original:
 *   if (tile_index < count_16x16):
 *       ptr = pixels_base + tile_index * 0x100
 *   else:
 *       ptr = pixels_base + count_16x16 * 0x80 + tile_index * 0x80
 */
const u8* GetTilePixelDataPtr(const LevelContext* ctx, u16 tile_index);

/**
 * Copy tile pixel data to destination buffer.
 * Matches CopyTilePixelData @ 0x8007b588.
 * 
 * @param ctx           Level context
 * @param tile_index    1-based tile index (0 = transparent)
 * @param dest          Destination buffer
 * @param dest_stride   Bytes per row in destination
 * @return              1 on success, 0 if tile_index == 0
 */
int CopyTilePixelData(const LevelContext* ctx, u16 tile_index, 
                      u8* dest, u16 dest_stride);

/* -----------------------------------------------------------------------------
 * PSX Color Conversion
 * PSX format: 0BBBBBGGGGGRRRRR (15-bit BGR)
 * -------------------------------------------------------------------------- */

/**
 * Convert PSX 15-bit color to 32-bit RGBA.
 * Color 0 is typically transparent.
 */
static inline u32 PSXColorToRGBA(u16 psx_color) {
    u8 r = ((psx_color >>  0) & 0x1F) << 3;
    u8 g = ((psx_color >>  5) & 0x1F) << 3;
    u8 b = ((psx_color >> 10) & 0x1F) << 3;
    u8 a = (psx_color == 0) ? 0 : 255;
    return ((u32)r) | ((u32)g << 8) | ((u32)b << 16) | ((u32)a << 24);
}

/**
 * Convert tile to RGBA pixels.
 * 
 * @param ctx           Level context
 * @param tile_index    1-based tile index
 * @param out_rgba      Output buffer (16*16*4 or 8*8*4 bytes)
 * @param out_width     Output: tile width (8 or 16)
 * @param out_height    Output: tile height (8 or 16)
 * @return              0 on success, -1 on error
 */
int RenderTileToRGBA(const LevelContext* ctx, u16 tile_index,
                     u8* out_rgba, int* out_width, int* out_height);

/**
 * Render an entire layer to an RGBA buffer.
 * 
 * @param ctx           Level context
 * @param layer_index   Layer index (0-based)
 * @param out_rgba      Output buffer (width * height * 4 bytes)
 * @param buf_width     Buffer width in pixels
 * @param buf_height    Buffer height in pixels
 * @return              0 on success, -1 on error
 */
int RenderLayerToRGBA(const LevelContext* ctx, u32 layer_index,
                      u8* out_rgba, int buf_width, int buf_height);

/**
 * Get layer dimensions in pixels.
 */
void GetLayerPixelDimensions(const LevelContext* ctx, u32 layer_index,
                             int* out_width, int* out_height);

#endif /* RENDER_H */
