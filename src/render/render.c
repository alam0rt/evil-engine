/**
 * render.c - Tile and Sprite Rendering Implementation
 * 
 * Implements authentic accessor functions matching original decompiled patterns.
 */

#include "render.h"
#include <string.h>

/* -----------------------------------------------------------------------------
 * Helper: Read u32 from little-endian byte pointer
 * -------------------------------------------------------------------------- */

static u32 read_u32_le(const u8* ptr) {
    return (u32)ptr[0] | ((u32)ptr[1] << 8) | 
           ((u32)ptr[2] << 16) | ((u32)ptr[3] << 24);
}

/* -----------------------------------------------------------------------------
 * GetPaletteDataPtr
 * Based on Ghidra @ 0x8007b4f8:
 *   iVar1 = *(int *)(param_1 + 0x20);
 *   if (iVar1 == 0) return 0;
 *   return iVar1 + *(int *)(iVar1 + (index & 0xff) * 0xc + 0xc);
 * -------------------------------------------------------------------------- */

const u16* GetPaletteDataPtr(const LevelContext* ctx, u8 palette_index) {
    const u8* container;
    u32 offset;
    
    container = ctx->palette_container;
    if (container == NULL) {
        return NULL;
    }
    
    /* Sub-TOC entry: 12 bytes per entry, offset at +8 within entry */
    /* First 4 bytes of container is count, entries start at +4 */
    /* Entry[n] at: container + 4 + n * 12 */
    /* Offset within entry at: entry + 8 */
    offset = read_u32_le(container + 4 + ((u32)palette_index * 12) + 8);
    
    return (const u16*)(container + offset);
}

/* -----------------------------------------------------------------------------
 * GetTilemapDataPtr
 * Based on Ghidra @ 0x8007b6dc:
 *   container = *(int *)(param_1 + 0xc);
 *   return container + *(int *)(container + layer * 0xc + 0xc);
 * -------------------------------------------------------------------------- */

const u16* GetTilemapDataPtr(const LevelContext* ctx, u32 layer_index) {
    const u8* container;
    u32 offset;
    
    container = ctx->tilemap_container;
    if (container == NULL) {
        return NULL;
    }
    
    /* Same sub-TOC pattern as palette container */
    /* Entry[n] at: container + 4 + n * 12 */
    /* Offset within entry at: entry + 8 */
    offset = read_u32_le(container + 4 + (layer_index * 12) + 8);
    
    return (const u16*)(container + offset);
}

/* -----------------------------------------------------------------------------
 * GetTilePixelDataPtr
 * Based on CopyTilePixelData @ 0x8007b588 layout calculations
 * -------------------------------------------------------------------------- */

const u8* GetTilePixelDataPtr(const LevelContext* ctx, u16 tile_index) {
    u32 count_16x16;
    u32 idx;
    const u8* base;
    
    if (!ctx->tile_pixels || !ctx->tile_header || tile_index == 0) {
        return NULL;
    }
    
    base = ctx->tile_pixels;
    idx = tile_index - 1;  /* tile_index is 1-based */
    count_16x16 = ctx->tile_header->count_16x16;
    
    if (idx < count_16x16) {
        /* 16x16 tile: 256 bytes each */
        return base + (idx * 0x100);
    } else {
        /* 8x8 tile: 128 bytes each, after all 16x16 tiles */
        /* Note: Original uses count_16x16 * 0x80 + idx * 0x80 */
        /* which is equivalent to (count_16x16 + idx - count_16x16) * 0x80 */
        return base + (count_16x16 * 0x100) + ((idx - count_16x16) * 0x80);
    }
}

/* -----------------------------------------------------------------------------
 * CopyTilePixelData
 * Matches original @ 0x8007b588:
 *   if (tile_index == 0) return 0;
 *   idx = tile_index - 1;
 *   count_16x16 = *(ushort *)(header + 0x10);
 *   if (idx < count_16x16):
 *       src = pixels_base + idx * 0x100; row_width = 16;
 *   else:
 *       src = pixels_base + count_16x16 * 0x80 + idx * 0x80; row_width = 8;
 *   for (row = 0; row < 16; row++):
 *       memcpy(dest, src, row_width);
 *       dest += stride;
 *       src += row_width;
 *   return 1;
 * -------------------------------------------------------------------------- */

int CopyTilePixelData(const LevelContext* ctx, u16 tile_index, 
                      u8* dest, u16 dest_stride) {
    u32 count_16x16;
    u32 idx;
    const u8* src;
    int row_width;
    u16 row;
    
    if (tile_index == 0) {
        return 0;
    }
    
    if (!ctx->tile_pixels || !ctx->tile_header) {
        return 0;
    }
    
    idx = tile_index - 1;
    count_16x16 = ctx->tile_header->count_16x16;
    
    if (idx < count_16x16) {
        src = ctx->tile_pixels + (idx * 0x100);
        row_width = 16;
    } else {
        src = ctx->tile_pixels + (count_16x16 * 0x100) + ((idx - count_16x16) * 0x80);
        row_width = 8;
    }
    
    /* Copy 16 rows (8 rows for 8x8 tiles, but we copy 16 anyway per original) */
    for (row = 0; row < 16; row++) {
        memcpy(dest, src, row_width);
        dest += dest_stride;
        src += row_width;
    }
    
    return 1;
}

/* -----------------------------------------------------------------------------
 * RenderTileToRGBA
 * Convert indexed tile to RGBA for display (helper for Godot wrapper)
 * -------------------------------------------------------------------------- */

int RenderTileToRGBA(const LevelContext* ctx, u16 tile_index,
                     u8* out_rgba, int* out_width, int* out_height) {
    const u8* pixels;
    const u16* palette;
    u8 palette_index;
    int is_8x8;
    int width, height;
    int x, y;
    u32 rgba;
    
    if (!ctx || tile_index == 0 || !out_rgba) {
        return -1;
    }
    
    /* Get palette for this tile */
    if (!ctx->palette_indices || tile_index > ctx->total_tiles) {
        return -1;
    }
    palette_index = ctx->palette_indices[tile_index - 1];
    palette = GetPaletteDataPtr(ctx, palette_index);
    if (!palette) {
        return -1;
    }
    
    /* Get pixel data */
    pixels = GetTilePixelDataPtr(ctx, tile_index);
    if (!pixels) {
        return -1;
    }
    
    /* Determine tile size */
    is_8x8 = 0;
    if (ctx->tile_flags && tile_index <= ctx->total_tiles) {
        is_8x8 = (ctx->tile_flags[tile_index - 1] & TILE_FLAG_8X8) != 0;
    } else if (ctx->tile_header && (tile_index - 1) >= ctx->tile_header->count_16x16) {
        is_8x8 = 1;
    }
    
    width = is_8x8 ? 8 : 16;
    height = is_8x8 ? 8 : 16;
    
    if (out_width) *out_width = width;
    if (out_height) *out_height = height;
    
    /* Convert indexed pixels to RGBA */
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            u8 color_index;
            u16 psx_color;
            int src_offset, dst_offset;
            
            /* Source layout: row-major, 8 or 16 bytes per row */
            if (is_8x8) {
                src_offset = y * 16 + x;  /* 16-byte stride even for 8x8 */
            } else {
                src_offset = y * 16 + x;
            }
            
            color_index = pixels[src_offset];
            psx_color = palette[color_index];
            rgba = PSXColorToRGBA(psx_color);
            
            /* Output: RGBA format */
            dst_offset = (y * width + x) * 4;
            out_rgba[dst_offset + 0] = (rgba >>  0) & 0xFF;  /* R */
            out_rgba[dst_offset + 1] = (rgba >>  8) & 0xFF;  /* G */
            out_rgba[dst_offset + 2] = (rgba >> 16) & 0xFF;  /* B */
            out_rgba[dst_offset + 3] = (rgba >> 24) & 0xFF;  /* A */
        }
    }
    
    return 0;
}

/* -----------------------------------------------------------------------------
 * GetLayerPixelDimensions
 * Get layer dimensions in pixels
 * -------------------------------------------------------------------------- */

void GetLayerPixelDimensions(const LevelContext* ctx, u32 layer_index,
                             int* out_width, int* out_height) {
    const LayerEntry* layer;
    
    if (out_width) *out_width = 0;
    if (out_height) *out_height = 0;
    
    layer = Level_GetLayer(ctx, layer_index);
    if (!layer) return;
    
    if (out_width) *out_width = layer->width * 16;
    if (out_height) *out_height = layer->height * 16;
}

/* -----------------------------------------------------------------------------
 * RenderLayerToRGBA
 * Render an entire layer to an RGBA buffer
 * -------------------------------------------------------------------------- */

int RenderLayerToRGBA(const LevelContext* ctx, u32 layer_index,
                      u8* out_rgba, int buf_width, int buf_height) {
    const u16* tilemap;
    const LayerEntry* layer;
    u32 lw, lh;
    u32 tx, ty;
    u8 tile_rgba[16 * 16 * 4];
    int tile_w, tile_h;
    
    if (!ctx || !out_rgba) return -1;
    
    layer = Level_GetLayer(ctx, layer_index);
    if (!layer) return -1;
    
    tilemap = GetTilemapDataPtr(ctx, layer_index);
    if (!tilemap) return -1;
    
    lw = layer->width;
    lh = layer->height;
    
    for (ty = 0; ty < lh && (ty * 16) < (u32)buf_height; ty++) {
        for (tx = 0; tx < lw && (tx * 16) < (u32)buf_width; tx++) {
            u16 tile_entry;
            u16 tile_index;
            int px, py;
            int x, y;
            
            tile_entry = tilemap[ty * lw + tx];
            tile_index = tile_entry & 0xFFF;  /* bits 0-11 (12 bits) */
            
            if (tile_index == 0) continue;  /* transparent */
            
            /* Render tile to temporary buffer */
            if (RenderTileToRGBA(ctx, tile_index, tile_rgba, &tile_w, &tile_h) != 0) {
                continue;
            }
            
            /* Copy to output image */
            px = tx * 16;
            py = ty * 16;
            
            for (y = 0; y < tile_h && (py + y) < buf_height; y++) {
                for (x = 0; x < tile_w && (px + x) < buf_width; x++) {
                    int src_idx = (y * tile_w + x) * 4;
                    int dst_idx = ((py + y) * buf_width + (px + x)) * 4;
                    u8 a = tile_rgba[src_idx + 3];
                    
                    /* Skip fully transparent pixels */
                    if (a == 0) continue;
                    
                    /* Copy RGBA */
                    out_rgba[dst_idx + 0] = tile_rgba[src_idx + 0];
                    out_rgba[dst_idx + 1] = tile_rgba[src_idx + 1];
                    out_rgba[dst_idx + 2] = tile_rgba[src_idx + 2];
                    out_rgba[dst_idx + 3] = a;
                }
            }
        }
    }
    
    return 0;
}
