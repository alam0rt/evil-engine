/**
 * level.h - Level Loading and Data Structures
 * 
 * Manages loading of level data from BLB segments and provides
 * access to tiles, layers, palettes, and entities.
 * 
 * Based on LevelDataContext structure from the original game
 * (located at GameState + 0x84, or 0x8009DCC4 in PAL).
 */

#ifndef LEVEL_H
#define LEVEL_H

#include "../psx/types.h"
#include "../psx/libgpu.h"
#include "../blb/blb.h"

/* -----------------------------------------------------------------------------
 * Tile Header (Asset 100) - 36 bytes
 * -------------------------------------------------------------------------- */

typedef struct {
    /* Background color (0x00-0x03) */
    u8  bg_r, bg_g, bg_b;
    u8  pad_03;
    
    /* Secondary/fog color (0x04-0x07) */
    u8  fog_r, fog_g, fog_b;
    u8  pad_07;
    
    /* Level dimensions in tiles (0x08-0x0B) */
    u16 level_width;
    u16 level_height;
    
    /* Player spawn position in tiles (0x0C-0x0F) */
    u16 spawn_x;
    u16 spawn_y;
    
    /* Tile counts (0x10-0x15) */
    u16 count_16x16;        /* Number of 16x16 tiles */
    u16 count_8x8;          /* Number of 8x8 tiles */
    u16 count_extra;        /* Additional tiles (often 0) */
    
    /* Vehicle/special data (0x16-0x17) */
    u16 vehicle_waypoints;  /* FINN/RUNN only */
    
    /* Level flags (0x18-0x19) */
    u16 level_flags;
    
    /* Special level ID (0x1A-0x1B) */
    u16 special_level_id;   /* 99 = special mode (FINN/SEVN) */
    
    /* Cross-asset counts (0x1C-0x1F) */
    u16 vram_rect_count;    /* Matches Asset 502 entries */
    u16 entity_count;       /* Matches Asset 501 entries */
    
    /* Unknown (0x20-0x23) */
    u16 field_20;
    u16 padding;
} TileHeader;

/* -----------------------------------------------------------------------------
 * Layer Entry (Asset 201) - 92 bytes
 * -------------------------------------------------------------------------- */

typedef struct {
    u8 r, g, b;
} ColorTint;

typedef struct {
    /* Position and dimensions (0x00-0x0B) */
    u16 x_offset;
    u16 y_offset;
    u16 width;              /* Layer width in tiles */
    u16 height;             /* Layer height in tiles */
    u16 level_width;        /* Level width (copy from TileHeader) */
    u16 level_height;       /* Level height */
    
    /* Render parameter (0x0C-0x0F) */
    u32 render_param;
    
    /* Scroll/parallax factors (0x10-0x17) */
    /* 0x10000 = 1.0 (camera speed), 0x8000 = 0.5 (parallax) */
    u32 scroll_x;
    u32 scroll_y;
    
    /* Render context fields (0x18-0x1D) */
    u16 render_field_30;
    u16 render_field_32;
    u8  render_field_3a;
    u8  render_field_3b;
    
    /* Scroll enable flags (0x1E-0x21) */
    u8  scroll_left_enable;
    u8  scroll_right_enable;
    u8  scroll_up_enable;
    u8  scroll_down_enable;
    
    /* Render mode selection (0x22-0x25) */
    u16 render_mode_h;
    u16 render_mode_v;
    
    /* Layer type (0x26) */
    u8  layer_type;         /* 0=normal, 3=skip */
    u8  pad_27;
    
    /* Skip render flag (0x28-0x29) */
    u16 skip_render;
    u16 unknown_2a;
    
    /* Color tint table (0x2C-0x5B) - 16 RGB entries */
    ColorTint color_tints[16];
    
} LayerEntry;

/* -----------------------------------------------------------------------------
 * Entity Definition (Asset 501) - 24 bytes
 * -------------------------------------------------------------------------- */

typedef struct {
    /* Bounding box in pixels (0x00-0x07) */
    u16 x1, y1;             /* Min corner */
    u16 x2, y2;             /* Max corner */
    
    /* Center position (0x08-0x0B) */
    u16 x_center;
    u16 y_center;
    
    /* Variant/subtype (0x0C-0x0D) */
    u16 variant;
    
    /* Padding (0x0E-0x11) */
    u16 padding1;
    u16 padding2;
    
    /* Entity type (0x12-0x13) */
    u16 entity_type;
    
    /* Layer with flags (0x14-0x15) */
    u16 layer;
    
    /* Padding (0x16-0x17) */
    u16 padding3;
} EntityDef;

/* -----------------------------------------------------------------------------
 * Level Context
 * 
 * Simplified version of original LevelDataContext (22 pointers).
 * Stores pointers to loaded asset data.
 * -------------------------------------------------------------------------- */

typedef struct {
    /* Source BLB file */
    const BLBFile*  blb;
    
    /* Current level/stage */
    u8              level_index;
    u8              stage_index;
    u16             _pad;
    
    /* Segment base pointers */
    const u8*       primary_data;
    const u8*       secondary_data;
    const u8*       tertiary_data;
    
    /* Tile Header (Asset 100) */
    const TileHeader* tile_header;
    
    /* Tile graphics data */
    const u8*       tile_pixels;        /* Asset 300: 8bpp indexed */
    const u8*       palette_indices;    /* Asset 301: palette per tile */
    const u8*       tile_flags;         /* Asset 302: size/render flags */
    
    /* Palette data (Asset 400 container) */
    const u8*       palette_container;
    u32             palette_count;
    
    /* Layer data */
    const u8*       tilemap_container;  /* Asset 200 */
    const LayerEntry* layer_entries;    /* Asset 201 */
    u32             layer_count;
    
    /* Entity data */
    const EntityDef* entities;          /* Asset 501 */
    u32             entity_count;
    
    /* Computed values */
    u32             total_tiles;        /* 16x16 + 8x8 + extra */
    
} LevelContext;

/* -----------------------------------------------------------------------------
 * Level Operations
 * -------------------------------------------------------------------------- */

/**
 * Initialize a level context.
 */
void Level_Init(LevelContext* ctx);

/**
 * Unload level data and free resources.
 */
void Level_Unload(LevelContext* ctx);

/**
 * Load a level and stage from a BLB file.
 * 
 * @param ctx           Level context to populate
 * @param blb           BLB file handle
 * @param level_index   Level index (0-25)
 * @param stage_index   Stage index (0-5)
 * @return              0 on success, -1 on error
 */
int Level_Load(LevelContext* ctx, const BLBFile* blb, u8 level_index, u8 stage_index);

/**
 * Get total tile count (16x16 + 8x8 + extra).
 */
u32 Level_GetTotalTileCount(const LevelContext* ctx);

/**
 * Get pointer to a specific tile's pixel data.
 * 
 * @param ctx           Level context
 * @param tile_index    Tile index (0-based)
 * @param out_is_8x8    Output: true if this is an 8x8 tile
 * @return              Pointer to pixel data (256 or 128 bytes)
 */
const u8* Level_GetTilePixels(const LevelContext* ctx, u16 tile_index, int* out_is_8x8);

/**
 * Get palette for a specific tile.
 * 
 * @param ctx           Level context
 * @param tile_index    Tile index
 * @return              Pointer to 256-color palette (512 bytes, PSX 15-bit)
 */
const u16* Level_GetTilePalette(const LevelContext* ctx, u16 tile_index);

/**
 * Get tile flags for rendering.
 * Bit 0: semi-transparent
 * Bit 1: 8x8 tile (not 16x16)
 * Bit 2: skip/don't render
 */
u8 Level_GetTileFlags(const LevelContext* ctx, u16 tile_index);

/**
 * Get layer entry by index.
 */
const LayerEntry* Level_GetLayer(const LevelContext* ctx, u32 layer_index);

/**
 * Get tilemap data for a layer.
 * Returns pointer to width*height u16 values.
 * Each u16: bits 0-10 = tile index (1-based, 0=transparent)
 *           bits 12-15 = color tint selector
 */
const u16* Level_GetLayerTilemap(const LevelContext* ctx, u32 layer_index);

/**
 * Get background color from tile header.
 */
void Level_GetBackgroundColor(const LevelContext* ctx, u8* r, u8* g, u8* b);

/**
 * Get spawn position in pixels.
 */
void Level_GetSpawnPosition(const LevelContext* ctx, s32* x, s32* y);

/* -----------------------------------------------------------------------------
 * Level Data Packing (for BLB Export)
 * -------------------------------------------------------------------------- */

/**
 * Pack tilemap data into BLB Asset 200 format.
 * Returns allocated buffer (caller must free).
 * 
 * @param tilemap_data  Array of u16 tilemap values
 * @param width         Layer width in tiles
 * @param height        Layer height in tiles
 * @param out_size      Output: packed data size
 * @return              Allocated buffer, or NULL on error
 */
u8* Level_PackTilemap(const u16* tilemap_data, u32 width, u32 height, u32* out_size);

/**
 * Pack layer entries into BLB Asset 201 format.
 * Returns allocated buffer (caller must free).
 * 
 * @param layers        Array of LayerEntry structures
 * @param count         Number of layers
 * @param out_size      Output: packed data size
 * @return              Allocated buffer, or NULL on error
 */
u8* Level_PackLayers(const LayerEntry* layers, u32 count, u32* out_size);

/**
 * Pack entity definitions into BLB Asset 501 format.
 * Returns allocated buffer (caller must free).
 * 
 * @param entities      Array of EntityDef structures
 * @param count         Number of entities
 * @param out_size      Output: packed data size
 * @return              Allocated buffer, or NULL on error
 */
u8* Level_PackEntities(const EntityDef* entities, u32 count, u32* out_size);

/**
 * Pack tile pixel data into BLB Asset 300 format (8bpp indexed).
 * Returns allocated buffer (caller must free).
 * 
 * @param pixels        Array of tile pixel data (indexed 8bpp)
 * @param tile_count    Number of tiles
 * @param out_size      Output: packed data size
 * @return              Allocated buffer, or NULL on error
 */
u8* Level_PackTilePixels(const u8* pixels, u32 tile_count, u32* out_size);

/**
 * Pack palette data into BLB Asset 400 container format.
 * Returns allocated buffer (caller must free).
 * 
 * @param palettes      Array of PSX 15-bit RGB palettes (u16 values)
 * @param palette_count Number of 256-color palettes
 * @param out_size      Output: packed data size
 * @return              Allocated buffer, or NULL on error
 */
u8* Level_PackPalettes(const u16* palettes, u32 palette_count, u32* out_size);

/**
 * Pack tile header into BLB Asset 100 format.
 * Returns allocated buffer (caller must free).
 * 
 * @param header        Tile header structure
 * @param out_size      Output: packed data size
 * @return              Allocated buffer, or NULL on error
 */
u8* Level_PackTileHeader(const TileHeader* header, u32* out_size);

/**
 * Build a complete primary segment from level context.
 * This includes all primary assets (tiles, layers, entities, palettes).
 * Returns allocated buffer (caller must free).
 * 
 * @param ctx           Level context with all data loaded
 * @param out_size      Output: segment size
 * @return              Allocated segment buffer, or NULL on error
 */
u8* Level_BuildPrimarySegment(const LevelContext* ctx, u32* out_size);

/**
 * Build a secondary segment for a stage.
 * Returns allocated buffer (caller must free).
 * 
 * @param ctx           Level context
 * @param stage         Stage index
 * @param out_size      Output: segment size
 * @return              Allocated segment buffer, or NULL on error
 */
u8* Level_BuildSecondarySegment(const LevelContext* ctx, u8 stage, u32* out_size);

/**
 * Build a tertiary segment for a stage.
 * Returns allocated buffer (caller must free).
 * 
 * @param ctx           Level context
 * @param stage         Stage index
 * @param out_size      Output: segment size
 * @return              Allocated segment buffer, or NULL on error
 */
u8* Level_BuildTertiarySegment(const LevelContext* ctx, u8 stage, u32* out_size);

#endif /* LEVEL_H */
