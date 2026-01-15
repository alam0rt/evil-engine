/**
 * evil_engine.c - Public API Implementation
 * 
 * Implements the standalone C99 library API.
 * This wraps the internal BLB and level code with a clean public interface.
 */

#include "evil_engine.h"
#include <stdlib.h>
#include <string.h>

/* -----------------------------------------------------------------------------
 * BLB File Operations (READ)
 * -------------------------------------------------------------------------- */

int EvilEngine_OpenBLB(const char* path, BLBFile** out_blb) {
    BLBFile* blb;
    
    if (!path || !out_blb) {
        return -1;
    }
    
    blb = (BLBFile*)calloc(1, sizeof(BLBFile));
    if (!blb) {
        return -1;
    }
    
    if (BLB_Open(path, blb) != 0) {
        free(blb);
        return -1;
    }
    
    *out_blb = blb;
    return 0;
}

void EvilEngine_CloseBLB(BLBFile* blb) {
    if (!blb) return;
    BLB_Close(blb);
    free(blb);
}

int EvilEngine_GetLevelCount(const BLBFile* blb) {
    if (!blb) return 0;
    return (int)BLB_GetLevelCount(blb);
}

const char* EvilEngine_GetLevelName(const BLBFile* blb, int index) {
    if (!blb) return NULL;
    return BLB_GetLevelName(blb, (u8)index);
}

const char* EvilEngine_GetLevelID(const BLBFile* blb, int index) {
    if (!blb) return NULL;
    return BLB_GetLevelID(blb, (u8)index);
}

/* -----------------------------------------------------------------------------
 * Level Operations (READ)
 * -------------------------------------------------------------------------- */

int EvilEngine_LoadLevel(const BLBFile* blb, int level_index, int stage_index,
                         LevelContext** out_level) {
    LevelContext* level;
    
    if (!blb || !out_level) {
        return -1;
    }
    
    level = (LevelContext*)calloc(1, sizeof(LevelContext));
    if (!level) {
        return -1;
    }
    
    Level_Init(level);
    
    if (Level_Load(level, blb, (u8)level_index, (u8)stage_index) != 0) {
        free(level);
        return -1;
    }
    
    *out_level = level;
    return 0;
}

void EvilEngine_UnloadLevel(LevelContext* level) {
    if (!level) return;
    Level_Unload(level);
    free(level);
}

/* -----------------------------------------------------------------------------
 * Data Accessors (READ)
 * -------------------------------------------------------------------------- */

const TileHeader* EvilEngine_GetTileHeader(const LevelContext* level) {
    if (!level) return NULL;
    return level->tile_header;
}

const LayerEntry* EvilEngine_GetLayer(const LevelContext* level, int layer_index) {
    if (!level) return NULL;
    return Level_GetLayer(level, (u32)layer_index);
}

int EvilEngine_GetLayerCount(const LevelContext* level) {
    if (!level) return 0;
    return (int)level->layer_count;
}

const EntityDef* EvilEngine_GetEntities(const LevelContext* level, int* out_count) {
    if (!level) {
        if (out_count) *out_count = 0;
        return NULL;
    }
    if (out_count) {
        *out_count = (int)level->entity_count;
    }
    return level->entities;
}

const u16* EvilEngine_GetLayerTilemap(const LevelContext* level, int layer_index) {
    if (!level) return NULL;
    return Level_GetLayerTilemap(level, (u32)layer_index);
}

const u8* EvilEngine_GetTilePixels(const LevelContext* level, int tile_index,
                                   int* out_is_8x8) {
    if (!level) {
        if (out_is_8x8) *out_is_8x8 = 0;
        return NULL;
    }
    return Level_GetTilePixels(level, (u16)tile_index, out_is_8x8);
}

const u16* EvilEngine_GetTilePalette(const LevelContext* level, int tile_index) {
    if (!level) return NULL;
    return Level_GetTilePalette(level, (u16)tile_index);
}

int EvilEngine_GetTotalTiles(const LevelContext* level) {
    if (!level) return 0;
    return (int)Level_GetTotalTileCount(level);
}

int EvilEngine_GetTileFlags(const LevelContext* level, int tile_index) {
    if (!level) return 0;
    return (int)Level_GetTileFlags(level, (u16)tile_index);
}

/* -----------------------------------------------------------------------------
 * Palette Operations
 * -------------------------------------------------------------------------- */

int EvilEngine_GetPaletteCount(const LevelContext* level) {
    if (!level || !level->palette_container) return 0;
    
    u32 count = 0;
    BLB_ParsePaletteContainer(level->palette_container, &count);
    return (int)count;
}

const u16* EvilEngine_GetPalette(const LevelContext* level, int palette_index, int* out_size) {
    u32 size = 0;
    const u16* palette;
    
    if (!level || !level->palette_container) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    palette = BLB_GetPaletteFromContainer(level->palette_container, (u8)palette_index, &size);
    if (out_size) *out_size = (int)size;
    
    return palette;
}

unsigned int EvilEngine_PSXColorToRGBA(unsigned short psx_color) {
    return BLB_PSXColorToRGBA(psx_color);
}

/* -----------------------------------------------------------------------------
 * Sprite Operations
 * -------------------------------------------------------------------------- */

int EvilEngine_GetSpriteCount(const unsigned char* segment_data, int* out_count) {
    u32 count = 0;
    int result = BLB_ParseSpriteContainer(segment_data, &count);
    if (out_count) *out_count = (int)count;
    return result;
}

const unsigned char* EvilEngine_GetSprite(const unsigned char* segment_data, int sprite_index,
                                          unsigned int* out_sprite_id, int* out_size) {
    u32 sprite_id = 0, size = 0;
    const u8* sprite = BLB_GetSpriteFromContainer(segment_data, (u32)sprite_index, &sprite_id, &size);
    
    if (out_sprite_id) *out_sprite_id = sprite_id;
    if (out_size) *out_size = (int)size;
    
    return sprite;
}

int EvilEngine_ParseSpriteHeader(const unsigned char* sprite_data, void* out_header) {
    return BLB_ParseSpriteHeader(sprite_data, (SpriteHeader*)out_header);
}

int EvilEngine_GetSpriteAnimation(const unsigned char* sprite_data, int anim_index, void* out_anim) {
    return BLB_GetSpriteAnimation(sprite_data, (u32)anim_index, (SpriteAnim*)out_anim);
}

int EvilEngine_GetSpriteFrameMetadata(const unsigned char* sprite_data, int frame_meta_offset,
                                      int frame_index, void* out_frame) {
    return BLB_GetSpriteFrameMetadata(sprite_data, (u16)frame_meta_offset, (u32)frame_index, (SpriteFrame*)out_frame);
}

const unsigned short* EvilEngine_GetSpritePalette(const unsigned char* sprite_data, unsigned int palette_offset) {
    return BLB_GetSpritePalette(sprite_data, palette_offset);
}

/* -----------------------------------------------------------------------------
 * Raw Asset Access
 * -------------------------------------------------------------------------- */

const unsigned char* EvilEngine_GetAssetData(const BLBFile* blb, int level_index, int stage_index,
                                             int segment_type, unsigned int asset_id, int* out_size) {
    u16 sector_offset;
    const u8* segment_data;
    const u8* asset_data;
    u32 size = 0;
    
    if (!blb) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Get appropriate segment sector */
    if (segment_type == 0) {
        /* Primary */
        sector_offset = BLB_GetPrimarySectorOffset(blb, (u8)level_index);
    } else if (segment_type == 1) {
        /* Secondary */
        sector_offset = BLB_GetSecondarySectorOffset(blb, (u8)level_index, (u8)stage_index);
    } else if (segment_type == 2) {
        /* Tertiary */
        sector_offset = BLB_GetTertiarySectorOffset(blb, (u8)level_index, (u8)stage_index);
    } else {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    segment_data = BLB_GetSectorData(blb, sector_offset);
    if (!segment_data) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    asset_data = BLB_FindAsset(blb, segment_data, asset_id, &size);
    if (out_size) *out_size = (int)size;
    
    return asset_data;
}

/* -----------------------------------------------------------------------------
 * BLB File Operations (WRITE)
 * -------------------------------------------------------------------------- */

int EvilEngine_CreateBLB(int level_count, BLBFile** out_blb) {
    BLBFile* blb;
    
    if (!out_blb || level_count <= 0 || level_count > 26) {
        return -1;
    }
    
    blb = BLB_Create((u8)level_count);
    if (!blb) {
        return -1;
    }
    
    *out_blb = blb;
    return 0;
}

int EvilEngine_SetLevelMetadata(BLBFile* blb, int level_index,
                                const char* level_id, const char* level_name,
                                int stage_count) {
    if (!blb || !level_id || !level_name) {
        return -1;
    }
    
    return BLB_SetLevelMetadata(blb, (u8)level_index, level_id, level_name, 
                                (u16)stage_count);
}

int EvilEngine_WriteLevelData(BLBFile* blb, int level_index, int stage_index,
                              const u8* primary_data, u32 primary_size,
                              const u8* secondary_data, u32 secondary_size,
                              const u8* tertiary_data, u32 tertiary_size) {
    int result;
    
    if (!blb) {
        return -1;
    }
    
    /* Write primary segment */
    if (primary_data && primary_size > 0) {
        result = BLB_WriteSegment(blb, (u8)level_index, 0, primary_data, 
                                  primary_size, 0);
        if (result != 0) {
            return result;
        }
    }
    
    /* Write secondary segment */
    if (secondary_data && secondary_size > 0) {
        result = BLB_WriteSegment(blb, (u8)level_index, (u8)stage_index, 
                                  secondary_data, secondary_size, 1);
        if (result != 0) {
            return result;
        }
    }
    
    /* Write tertiary segment */
    if (tertiary_data && tertiary_size > 0) {
        result = BLB_WriteSegment(blb, (u8)level_index, (u8)stage_index, 
                                  tertiary_data, tertiary_size, 2);
        if (result != 0) {
            return result;
        }
    }
    
    return 0;
}

int EvilEngine_SaveBLB(const BLBFile* blb, const char* path) {
    if (!blb || !path) {
        return -1;
    }
    
    return BLB_WriteToFile(blb, path);
}

/* -----------------------------------------------------------------------------
 * Level Operations (WRITE)
 * -------------------------------------------------------------------------- */

u8* EvilEngine_BuildPrimarySegment(const LevelContext* level, u32* out_size) {
    SegmentBuilder builder;
    u8* segment;
    
    if (!level || !out_size) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Initialize segment builder */
    if (BLB_SegmentBuilder_Init(&builder) != 0) {
        *out_size = 0;
        return NULL;
    }
    
    /* Add primary assets (Asset 600 geometry container, 601 audio, 602 palettes) */
    /* TODO: Extract these from loaded level data */
    /* For now, return NULL as we need level data extraction implementation */
    
    BLB_SegmentBuilder_Free(&builder);
    *out_size = 0;
    return NULL;
}

u8* EvilEngine_BuildSecondarySegment(const LevelContext* level, int stage, u32* out_size) {
    SegmentBuilder builder;
    u8* segment;
    
    if (!level || !out_size) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Initialize segment builder */
    if (BLB_SegmentBuilder_Init(&builder) != 0) {
        *out_size = 0;
        return NULL;
    }
    
    /* Add secondary assets (Asset 100 tile header, 300-303 tiles, 400-401 palettes) */
    if (level->tile_header) {
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_TILE_HEADER, 
                                     (const u8*)level->tile_header, 
                                     sizeof(TileHeader));
    }
    
    /* Add tile pixel data */
    if (level->tile_pixels && level->tile_pixels_size > 0) {
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_TILE_PIXELS,
                                     level->tile_pixels,
                                     level->tile_pixels_size);
    }
    
    /* Add palette indices */
    if (level->palette_indices && level->palette_index_count > 0) {
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_PALETTE_INDICES,
                                     level->palette_indices,
                                     level->palette_index_count);
    }
    
    /* Add tile flags */
    if (level->tile_flags && level->tile_flag_count > 0) {
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_TILE_FLAGS,
                                     level->tile_flags,
                                     level->tile_flag_count);
    }
    
    /* Add palette container */
    if (level->palette_container) {
        u32 pal_size = 0;
        /* Get palette container size - first 4 bytes contain count */
        const u8* pal_data = (const u8*)level->palette_container;
        u32 pal_count = pal_data[0] | (pal_data[1] << 8) | (pal_data[2] << 16) | (pal_data[3] << 24);
        pal_size = 4 + pal_count * 12 + pal_count * 512;  /* Estimate */
        
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_PALETTE_CONTAINER,
                                     pal_data, pal_size);
    }
    
    /* Finalize segment */
    segment = BLB_SegmentBuilder_Finalize(&builder, out_size);
    BLB_SegmentBuilder_Free(&builder);
    
    return segment;
}

u8* EvilEngine_BuildTertiarySegment(const LevelContext* level, int stage, u32* out_size) {
    SegmentBuilder builder;
    u8* segment;
    
    if (!level || !out_size) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Initialize segment builder */
    if (BLB_SegmentBuilder_Init(&builder) != 0) {
        *out_size = 0;
        return NULL;
    }
    
    /* Add tertiary assets (Asset 200-201 layers, 500-504 gameplay data) */
    
    /* Add layer entries (Asset 201) */
    if (level->layers && level->layer_count > 0) {
        u32 layer_data_size = level->layer_count * sizeof(LayerEntry);
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_LAYER_ENTRIES,
                                     (const u8*)level->layers,
                                     layer_data_size);
    }
    
    /* Add tilemap container (Asset 200) */
    if (level->tilemaps && level->tilemap_count > 0) {
        /* Build tilemap container with TOC */
        u32 total_size = 4;  /* TOC count */
        u32 i;
        for (i = 0; i < level->tilemap_count; i++) {
            total_size += 12;  /* TOC entry */
            total_size += level->tilemap_sizes[i];  /* Tilemap data */
        }
        
        u8* tilemap_container = (u8*)malloc(total_size);
        if (tilemap_container) {
            /* Write TOC */
            u32 offset = 4 + level->tilemap_count * 12;
            tilemap_container[0] = (u8)(level->tilemap_count & 0xFF);
            tilemap_container[1] = (u8)((level->tilemap_count >> 8) & 0xFF);
            tilemap_container[2] = (u8)((level->tilemap_count >> 16) & 0xFF);
            tilemap_container[3] = (u8)((level->tilemap_count >> 24) & 0xFF);
            
            /* Write TOC entries and data */
            for (i = 0; i < level->tilemap_count; i++) {
                u8* entry = tilemap_container + 4 + i * 12;
                u32 size = level->tilemap_sizes[i];
                
                /* ID */
                entry[0] = (u8)(i & 0xFF);
                entry[1] = (u8)((i >> 8) & 0xFF);
                entry[2] = (u8)((i >> 16) & 0xFF);
                entry[3] = (u8)((i >> 24) & 0xFF);
                
                /* Size */
                entry[4] = (u8)(size & 0xFF);
                entry[5] = (u8)((size >> 8) & 0xFF);
                entry[6] = (u8)((size >> 16) & 0xFF);
                entry[7] = (u8)((size >> 24) & 0xFF);
                
                /* Offset */
                entry[8] = (u8)(offset & 0xFF);
                entry[9] = (u8)((offset >> 8) & 0xFF);
                entry[10] = (u8)((offset >> 16) & 0xFF);
                entry[11] = (u8)((offset >> 24) & 0xFF);
                
                /* Copy tilemap data */
                memcpy(tilemap_container + offset, level->tilemaps[i], size);
                offset += size;
            }
            
            BLB_SegmentBuilder_AddAsset(&builder, ASSET_TILEMAP_CONTAINER,
                                         tilemap_container, total_size);
            free(tilemap_container);
        }
    }
    
    /* Add tile attributes (Asset 500) */
    if (level->tile_attributes && level->tile_attribute_size > 0) {
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_TILE_ATTRS,
                                     level->tile_attributes,
                                     level->tile_attribute_size);
    }
    
    /* Add entity data (Asset 501) */
    if (level->entities && level->entity_count > 0) {
        u32 entity_data_size = level->entity_count * sizeof(EntityDef);
        BLB_SegmentBuilder_AddAsset(&builder, ASSET_ENTITIES,
                                     (const u8*)level->entities,
                                     entity_data_size);
    }
    
    /* Finalize segment */
    segment = BLB_SegmentBuilder_Finalize(&builder, out_size);
    BLB_SegmentBuilder_Free(&builder);
    
    return segment;
}
