/**
 * level.c - Level Loading Implementation
 * 
 * Loads level data from BLB segments and provides access to tiles,
 * layers, palettes, and entities.
 */

#include "level.h"
#include <string.h>

/* -----------------------------------------------------------------------------
 * Internal helpers
 * -------------------------------------------------------------------------- */

static u32 read_u32(const u8* ptr) {
    return (u32)ptr[0] | ((u32)ptr[1] << 8) | 
           ((u32)ptr[2] << 16) | ((u32)ptr[3] << 24);
}

static u16 read_u16(const u8* ptr) {
    return (u16)ptr[0] | ((u16)ptr[1] << 8);
}

/* Get secondary segment for a stage (respects pairing rules) */
static u16 get_effective_secondary_sector(const BLBFile* blb, u8 level_index, u8 stage_index) {
    /* Stage 0 uses base secondary (stage 0's secondary offset)
     * Stage N uses stage (N-1)'s secondary for tiles
     * But for simplicity, we use the stage's own secondary for now */
    return BLB_GetSecondarySectorOffset(blb, level_index, stage_index);
}

/* -----------------------------------------------------------------------------
 * Level Operations
 * -------------------------------------------------------------------------- */

void Level_Init(LevelContext* ctx) {
    if (ctx) {
        memset(ctx, 0, sizeof(LevelContext));
    }
}

void Level_Unload(LevelContext* ctx) {
    if (ctx) {
        /* All pointers point into BLB mmapped data, nothing to free */
        /* Just reset the context */
        memset(ctx, 0, sizeof(LevelContext));
    }
}

int Level_Load(LevelContext* ctx, const BLBFile* blb, u8 level_index, u8 stage_index) {
    u16 primary_sector, secondary_sector, tertiary_sector;
    u32 toc_count;
    u32 asset_size;
    const u8* palette_toc;
    
    if (!ctx || !blb) {
        return -1;
    }
    
    Level_Init(ctx);
    
    /* Validate indices */
    if (level_index >= blb->level_count) {
        return -1;
    }
    
    if (stage_index >= BLB_GetStageCount(blb, level_index)) {
        return -1;
    }
    
    ctx->blb = blb;
    ctx->level_index = level_index;
    ctx->stage_index = stage_index;
    
    /* Get sector locations */
    primary_sector = BLB_GetPrimarySectorOffset(blb, level_index);
    secondary_sector = get_effective_secondary_sector(blb, level_index, stage_index);
    tertiary_sector = BLB_GetTertiarySectorOffset(blb, level_index, stage_index);
    
    /* Get segment base pointers */
    ctx->primary_data = BLB_GetSectorData(blb, primary_sector);
    ctx->secondary_data = BLB_GetSectorData(blb, secondary_sector);
    ctx->tertiary_data = BLB_GetSectorData(blb, tertiary_sector);
    
    if (!ctx->primary_data || !ctx->secondary_data || !ctx->tertiary_data) {
        return -1;
    }
    
    /* ---------------------------------------------------------------------
     * Load from SECONDARY segment (tile data)
     * --------------------------------------------------------------------- */
    
    /* Asset 100: Tile Header */
    ctx->tile_header = (const TileHeader*)BLB_FindAsset(
        blb, ctx->secondary_data, ASSET_TILE_HEADER, NULL);
    
    if (!ctx->tile_header) {
        return -1;
    }
    
    /* Compute total tiles */
    ctx->total_tiles = ctx->tile_header->count_16x16 + 
                       ctx->tile_header->count_8x8 + 
                       ctx->tile_header->count_extra;
    
    /* Asset 300: Tile Pixels (8bpp indexed) */
    ctx->tile_pixels = BLB_FindAsset(
        blb, ctx->secondary_data, ASSET_TILE_PIXELS, NULL);
    
    /* Asset 301: Palette Indices */
    ctx->palette_indices = BLB_FindAsset(
        blb, ctx->secondary_data, ASSET_PALETTE_INDICES, NULL);
    
    /* Asset 302: Tile Flags */
    ctx->tile_flags = BLB_FindAsset(
        blb, ctx->secondary_data, ASSET_TILE_FLAGS, NULL);
    
    /* Asset 400: Palette Container */
    ctx->palette_container = BLB_FindAsset(
        blb, ctx->secondary_data, ASSET_PALETTE_CONTAINER, &asset_size);
    
    if (ctx->palette_container) {
        /* Palette container has sub-TOC: first u32 is count */
        ctx->palette_count = read_u32(ctx->palette_container);
    }
    
    /* ---------------------------------------------------------------------
     * Load from TERTIARY segment (layers, entities)
     * --------------------------------------------------------------------- */
    
    /* Asset 200: Tilemap Container */
    ctx->tilemap_container = BLB_FindAsset(
        blb, ctx->tertiary_data, ASSET_TILEMAP_CONTAINER, NULL);
    
    /* Asset 201: Layer Entries */
    ctx->layer_entries = (const LayerEntry*)BLB_FindAsset(
        blb, ctx->tertiary_data, ASSET_LAYER_ENTRIES, &asset_size);
    
    if (ctx->layer_entries && asset_size > 0) {
        ctx->layer_count = asset_size / sizeof(LayerEntry);
    }
    
    /* Asset 501: Entity Definitions */
    ctx->entities = (const EntityDef*)BLB_FindAsset(
        blb, ctx->tertiary_data, ASSET_ENTITIES, &asset_size);
    
    if (ctx->entities && asset_size > 0) {
        ctx->entity_count = asset_size / sizeof(EntityDef);
    } else if (ctx->tile_header) {
        /* Fallback to count from tile header */
        ctx->entity_count = ctx->tile_header->entity_count;
    }
    
    return 0;
}

u32 Level_GetTotalTileCount(const LevelContext* ctx) {
    return ctx ? ctx->total_tiles : 0;
}

const u8* Level_GetTilePixels(const LevelContext* ctx, u16 tile_index, int* out_is_8x8) {
    u32 offset;
    int is_8x8;
    
    if (!ctx || !ctx->tile_pixels || !ctx->tile_header) {
        if (out_is_8x8) *out_is_8x8 = 0;
        return NULL;
    }
    
    if (tile_index >= ctx->total_tiles) {
        if (out_is_8x8) *out_is_8x8 = 0;
        return NULL;
    }
    
    /* Check if this is a 16x16 or 8x8 tile */
    if (tile_index < ctx->tile_header->count_16x16) {
        /* 16x16 tile: 256 bytes each (16 rows × 16 bytes) */
        is_8x8 = 0;
        offset = tile_index * 256;
    } else {
        /* 8x8 tile: 128 bytes each (8 rows × 16 bytes, only first 8 cols used) */
        is_8x8 = 1;
        offset = ctx->tile_header->count_16x16 * 256 + 
                 (tile_index - ctx->tile_header->count_16x16) * 128;
    }
    
    if (out_is_8x8) *out_is_8x8 = is_8x8;
    return ctx->tile_pixels + offset;
}

const u16* Level_GetTilePalette(const LevelContext* ctx, u16 tile_index) {
    u8 palette_index;
    u32 sub_toc_count;
    const u8* sub_toc;
    u32 palette_offset;
    
    if (!ctx || !ctx->palette_container || !ctx->palette_indices) {
        return NULL;
    }
    
    if (tile_index >= ctx->total_tiles) {
        return NULL;
    }
    
    /* Get palette index for this tile */
    palette_index = ctx->palette_indices[tile_index];
    
    /* Read sub-TOC from palette container */
    sub_toc_count = read_u32(ctx->palette_container);
    if (palette_index >= sub_toc_count) {
        return NULL;
    }
    
    /* Sub-TOC entries are 12 bytes each (same as TOCEntry) */
    sub_toc = ctx->palette_container + 4 + (palette_index * 12);
    palette_offset = read_u32(sub_toc + 8);  /* Offset is at +8 */
    
    return (const u16*)(ctx->palette_container + palette_offset);
}

u8 Level_GetTileFlags(const LevelContext* ctx, u16 tile_index) {
    if (!ctx || !ctx->tile_flags || tile_index >= ctx->total_tiles) {
        return 0;
    }
    return ctx->tile_flags[tile_index];
}

const LayerEntry* Level_GetLayer(const LevelContext* ctx, u32 layer_index) {
    if (!ctx || !ctx->layer_entries || layer_index >= ctx->layer_count) {
        return NULL;
    }
    return &ctx->layer_entries[layer_index];
}

const u16* Level_GetLayerTilemap(const LevelContext* ctx, u32 layer_index) {
    const u8* tilemap_toc;
    u32 toc_count;
    u32 tilemap_offset;
    
    if (!ctx || !ctx->tilemap_container || layer_index >= ctx->layer_count) {
        return NULL;
    }
    
    /* Tilemap container has sub-TOC */
    toc_count = read_u32(ctx->tilemap_container);
    if (layer_index >= toc_count) {
        return NULL;
    }
    
    /* Read offset from sub-TOC (12 bytes per entry) */
    tilemap_toc = ctx->tilemap_container + 4 + (layer_index * 12);
    tilemap_offset = read_u32(tilemap_toc + 8);
    
    return (const u16*)(ctx->tilemap_container + tilemap_offset);
}

void Level_GetBackgroundColor(const LevelContext* ctx, u8* r, u8* g, u8* b) {
    if (!ctx || !ctx->tile_header) {
        if (r) *r = 0;
        if (g) *g = 0;
        if (b) *b = 0;
        return;
    }
    
    if (r) *r = ctx->tile_header->bg_r;
    if (g) *g = ctx->tile_header->bg_g;
    if (b) *b = ctx->tile_header->bg_b;
}

void Level_GetSpawnPosition(const LevelContext* ctx, s32* x, s32* y) {
    if (!ctx || !ctx->tile_header) {
        if (x) *x = 0;
        if (y) *y = 0;
        return;
    }
    
    /* Convert tile position to pixel position */
    /* spawn_x_pixels = spawn_x * 16 + 8 */
    /* spawn_y_pixels = spawn_y * 16 + 15 */
    if (x) *x = ctx->tile_header->spawn_x * 16 + 8;
    if (y) *y = ctx->tile_header->spawn_y * 16 + 15;
}
