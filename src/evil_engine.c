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
 * TODO: Implement in Phase 2
 * -------------------------------------------------------------------------- */

int EvilEngine_CreateBLB(int level_count, BLBFile** out_blb) {
    (void)level_count;
    (void)out_blb;
    /* TODO: Implement BLB creation */
    return -1;
}

int EvilEngine_SetLevelMetadata(BLBFile* blb, int level_index,
                                const char* level_id, const char* level_name,
                                int stage_count) {
    (void)blb;
    (void)level_index;
    (void)level_id;
    (void)level_name;
    (void)stage_count;
    /* TODO: Implement metadata setting */
    return -1;
}

int EvilEngine_WriteLevelData(BLBFile* blb, int level_index, int stage_index,
                              const u8* primary_data, u32 primary_size,
                              const u8* secondary_data, u32 secondary_size,
                              const u8* tertiary_data, u32 tertiary_size) {
    (void)blb;
    (void)level_index;
    (void)stage_index;
    (void)primary_data;
    (void)primary_size;
    (void)secondary_data;
    (void)secondary_size;
    (void)tertiary_data;
    (void)tertiary_size;
    /* TODO: Implement level data writing */
    return -1;
}

int EvilEngine_SaveBLB(const BLBFile* blb, const char* path) {
    (void)blb;
    (void)path;
    /* TODO: Implement BLB save */
    return -1;
}

/* -----------------------------------------------------------------------------
 * Level Operations (WRITE)
 * TODO: Implement in Phase 2
 * -------------------------------------------------------------------------- */

u8* EvilEngine_BuildPrimarySegment(const LevelContext* level, u32* out_size) {
    (void)level;
    if (out_size) *out_size = 0;
    /* TODO: Implement primary segment builder */
    return NULL;
}

u8* EvilEngine_BuildSecondarySegment(const LevelContext* level, int stage, u32* out_size) {
    (void)level;
    (void)stage;
    if (out_size) *out_size = 0;
    /* TODO: Implement secondary segment builder */
    return NULL;
}

u8* EvilEngine_BuildTertiarySegment(const LevelContext* level, int stage, u32* out_size) {
    (void)level;
    (void)stage;
    if (out_size) *out_size = 0;
    /* TODO: Implement tertiary segment builder */
    return NULL;
}
