/**
 * blb.c - BLB Archive File Implementation
 * 
 * Implements BLB file parsing and accessor functions.
 * Patterns match the original decompiled Skullmonkeys code.
 */

#include "blb.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* -----------------------------------------------------------------------------
 * Internal helpers
 * -------------------------------------------------------------------------- */

/* Read little-endian u16 from buffer */
static u16 read_u16(const u8* ptr) {
    return (u16)ptr[0] | ((u16)ptr[1] << 8);
}

/* Read little-endian u32 from buffer */
static u32 read_u32(const u8* ptr) {
    return (u32)ptr[0] | ((u32)ptr[1] << 8) | 
           ((u32)ptr[2] << 16) | ((u32)ptr[3] << 24);
}

/* Get pointer to level entry */
static const u8* get_level_entry(const BLBFile* blb, u8 level_index) {
    if (level_index >= blb->level_count) {
        return NULL;
    }
    return blb->header + BLB_OFF_LEVEL_TABLE + (level_index * BLB_LEVEL_ENTRY_SIZE);
}

/* Detect if this is a JP version BLB */
static int detect_jp_layout(const u8* header) {
    /* PAL: byte[3] at 0xCD0 is A-Z (65-90) - start of code field
     * JP: different layout, byte[3] would be different */
    u8 byte3 = header[0xCD3];
    return !(byte3 >= 65 && byte3 <= 90);
}

/* -----------------------------------------------------------------------------
 * BLB File Operations
 * -------------------------------------------------------------------------- */

int BLB_Open(const char* path, BLBFile* blb) {
    FILE* f;
    long size;
    u8* data;
    
    if (!path || !blb) {
        return -1;
    }
    
    memset(blb, 0, sizeof(BLBFile));
    
    f = fopen(path, "rb");
    if (!f) {
        return -1;
    }
    
    /* Get file size */
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size < BLB_HEADER_SIZE) {
        fclose(f);
        return -1;
    }
    
    /* Allocate and read entire file */
    data = (u8*)malloc(size);
    if (!data) {
        fclose(f);
        return -1;
    }
    
    if (fread(data, 1, size, f) != (size_t)size) {
        free(data);
        fclose(f);
        return -1;
    }
    
    fclose(f);
    
    /* Initialize from memory */
    return BLB_OpenMem(data, (u32)size, blb);
}

int BLB_OpenMem(const u8* data, u32 size, BLBFile* blb) {
    if (!data || !blb || size < BLB_HEADER_SIZE) {
        return -1;
    }
    
    blb->data = (u8*)data;
    blb->size = size;
    blb->header = (u8*)data;
    
    /* Detect version */
    blb->is_jp = detect_jp_layout(blb->header);
    
    /* Read counts from header */
    if (blb->is_jp) {
        blb->level_count = blb->header[0xF15];
        blb->movie_count = blb->header[0xF16];
        blb->sector_count = blb->header[0xF17];
    } else {
        blb->level_count = blb->header[BLB_OFF_LEVEL_COUNT];
        blb->movie_count = blb->header[BLB_OFF_MOVIE_COUNT];
        blb->sector_count = blb->header[BLB_OFF_SECTOR_COUNT];
    }
    
    return 0;
}

void BLB_Close(BLBFile* blb) {
    if (blb && blb->data) {
        free(blb->data);
        memset(blb, 0, sizeof(BLBFile));
    }
}

/* -----------------------------------------------------------------------------
 * Header Accessors
 * -------------------------------------------------------------------------- */

u8 BLB_GetLevelCount(const BLBFile* blb) {
    return blb ? blb->level_count : 0;
}

const char* BLB_GetLevelName(const BLBFile* blb, u8 level_index) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry) return NULL;
    return (const char*)(entry + LEVEL_OFF_LEVEL_NAME);
}

const char* BLB_GetLevelID(const BLBFile* blb, u8 level_index) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry) return NULL;
    return (const char*)(entry + LEVEL_OFF_LEVEL_ID);
}

u8 BLB_GetLevelAssetIndex(const BLBFile* blb, u8 level_index) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry) return 0;
    return entry[LEVEL_OFF_ASSET_INDEX];
}

u16 BLB_GetStageCount(const BLBFile* blb, u8 level_index) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry) return 0;
    return read_u16(entry + LEVEL_OFF_STAGE_COUNT);
}

u16 BLB_GetPrimarySectorOffset(const BLBFile* blb, u8 level_index) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry) return 0;
    return read_u16(entry + LEVEL_OFF_PRIMARY_SECTOR);
}

u16 BLB_GetPrimarySectorCount(const BLBFile* blb, u8 level_index) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry) return 0;
    return read_u16(entry + LEVEL_OFF_PRIMARY_COUNT);
}

u16 BLB_GetSecondarySectorOffset(const BLBFile* blb, u8 level_index, u8 stage) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry || stage >= BLB_MAX_STAGES) return 0;
    return read_u16(entry + LEVEL_OFF_SEC_SECTOR + (stage * 2));
}

u16 BLB_GetSecondarySectorCount(const BLBFile* blb, u8 level_index, u8 stage) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry || stage >= BLB_MAX_STAGES) return 0;
    return read_u16(entry + LEVEL_OFF_SEC_COUNT + (stage * 2));
}

u16 BLB_GetTertiarySectorOffset(const BLBFile* blb, u8 level_index, u8 stage) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry || stage >= BLB_MAX_STAGES) return 0;
    return read_u16(entry + LEVEL_OFF_TERT_SECTOR + (stage * 2));
}

u16 BLB_GetTertiarySectorCount(const BLBFile* blb, u8 level_index, u8 stage) {
    const u8* entry = get_level_entry(blb, level_index);
    if (!entry || stage >= BLB_MAX_STAGES) return 0;
    return read_u16(entry + LEVEL_OFF_TERT_COUNT + (stage * 2));
}

/* -----------------------------------------------------------------------------
 * Segment/Asset Access
 * -------------------------------------------------------------------------- */

const u8* BLB_GetSectorData(const BLBFile* blb, u16 sector_offset) {
    u32 byte_offset;
    
    if (!blb || !blb->data) return NULL;
    
    byte_offset = (u32)sector_offset * BLB_SECTOR_SIZE;
    if (byte_offset >= blb->size) return NULL;
    
    return blb->data + byte_offset;
}

const TOCEntry* BLB_GetSegmentTOC(const BLBFile* blb, u16 sector_offset, u32* out_count) {
    const u8* segment;
    u32 count;
    
    segment = BLB_GetSectorData(blb, sector_offset);
    if (!segment) {
        if (out_count) *out_count = 0;
        return NULL;
    }
    
    /* First u32 is entry count */
    count = read_u32(segment);
    
    /* Sanity check - shouldn't have more than 100 entries */
    if (count > 100) {
        if (out_count) *out_count = 0;
        return NULL;
    }
    
    if (out_count) *out_count = count;
    
    /* TOC entries start after count field */
    return (const TOCEntry*)(segment + 4);
}

const u8* BLB_FindAsset(const BLBFile* blb, const u8* segment_start, 
                        u32 asset_id, u32* out_size) {
    u32 count, i;
    const TOCEntry* toc;
    
    if (!blb || !segment_start) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Read TOC count */
    count = read_u32(segment_start);
    if (count > 100) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    toc = (const TOCEntry*)(segment_start + 4);
    
    /* Search for asset by ID */
    for (i = 0; i < count; i++) {
        if (toc[i].id == asset_id) {
            if (out_size) *out_size = toc[i].size;
            return segment_start + toc[i].offset;
        }
    }
    
    if (out_size) *out_size = 0;
    return NULL;
}

/* -----------------------------------------------------------------------------
 * Palette Parsing
 * -------------------------------------------------------------------------- */

int BLB_ParsePaletteContainer(const u8* palette_data, u32* out_count) {
    u32 count;
    
    if (!palette_data || !out_count) {
        if (out_count) *out_count = 0;
        return -1;
    }
    
    count = read_u32(palette_data);
    
    /* Sanity check - shouldn't have more than 256 palettes */
    if (count > 256) {
        *out_count = 0;
        return -1;
    }
    
    *out_count = count;
    return 0;
}

const u16* BLB_GetPaletteFromContainer(const u8* palette_data, u8 palette_index, u32* out_size) {
    u32 count, pal_offset, pal_size;
    const u8* sub_toc;
    
    if (!palette_data) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Read sub-TOC count */
    count = read_u32(palette_data);
    if (palette_index >= count) {
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Sub-TOC entries are 12 bytes each (same as TOCEntry) */
    sub_toc = palette_data + 4 + (palette_index * 12);
    pal_size = read_u32(sub_toc + 4);
    pal_offset = read_u32(sub_toc + 8);
    
    if (out_size) *out_size = pal_size;
    return (const u16*)(palette_data + pal_offset);
}

u32 BLB_PSXColorToRGBA(u16 psx_color) {
    u8 r, g, b, a;
    
    /* PSX format: 0BBBBBGGGGGRRRRR (5 bits per channel) */
    r = (psx_color & 0x1F) << 3;          /* Red: bits 0-4 */
    g = ((psx_color >> 5) & 0x1F) << 3;   /* Green: bits 5-9 */
    b = ((psx_color >> 10) & 0x1F) << 3;  /* Blue: bits 10-14 */
    
    /* Color index 0 is transparent, bit 15 = semi-transparent flag */
    a = (psx_color == 0) ? 0 : 255;
    
    /* Return as 0xAABBGGRR */
    return ((u32)a << 24) | ((u32)b << 16) | ((u32)g << 8) | r;
}

/* -----------------------------------------------------------------------------
 * Sprite Parsing
 * -------------------------------------------------------------------------- */

int BLB_ParseSpriteContainer(const u8* sprite_data, u32* out_count) {
    u32 count;
    
    if (!sprite_data || !out_count) {
        if (out_count) *out_count = 0;
        return -1;
    }
    
    count = read_u32(sprite_data);
    
    /* Sanity check - shouldn't have more than 500 sprites */
    if (count > 500) {
        *out_count = 0;
        return -1;
    }
    
    *out_count = count;
    return 0;
}

const u8* BLB_GetSpriteFromContainer(const u8* sprite_data, u32 sprite_index,
                                     u32* out_sprite_id, u32* out_size) {
    u32 count, sprite_id, sprite_size, sprite_offset;
    const u8* toc_entry;
    
    if (!sprite_data) {
        if (out_sprite_id) *out_sprite_id = 0;
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* Read TOC count */
    count = read_u32(sprite_data);
    if (sprite_index >= count) {
        if (out_sprite_id) *out_sprite_id = 0;
        if (out_size) *out_size = 0;
        return NULL;
    }
    
    /* TOC entries are 12 bytes each */
    toc_entry = sprite_data + 4 + (sprite_index * 12);
    sprite_id = read_u32(toc_entry + 0);
    sprite_size = read_u32(toc_entry + 4);
    sprite_offset = read_u32(toc_entry + 8);
    
    if (out_sprite_id) *out_sprite_id = sprite_id;
    if (out_size) *out_size = sprite_size;
    
    return sprite_data + sprite_offset;
}

int BLB_ParseSpriteHeader(const u8* sprite_data, SpriteHeader* out_header) {
    if (!sprite_data || !out_header) {
        return -1;
    }
    
    out_header->anim_count = read_u16(sprite_data + 0);
    out_header->frame_meta_offset = read_u16(sprite_data + 2);
    out_header->rle_data_offset = read_u32(sprite_data + 4);
    out_header->palette_offset = read_u32(sprite_data + 8);
    
    /* Sanity check */
    if (out_header->anim_count > 100) {
        return -1;
    }
    
    return 0;
}

int BLB_GetSpriteAnimation(const u8* sprite_data, u32 anim_index, SpriteAnim* out_anim) {
    const u8* anim_data;
    SpriteHeader header;
    
    if (!sprite_data || !out_anim) {
        return -1;
    }
    
    /* Parse header to get anim count */
    if (BLB_ParseSpriteHeader(sprite_data, &header) != 0) {
        return -1;
    }
    
    if (anim_index >= header.anim_count) {
        return -1;
    }
    
    /* Animations start at offset 12 (after header), 12 bytes each */
    anim_data = sprite_data + 12 + (anim_index * 12);
    
    out_anim->anim_id = read_u32(anim_data + 0);
    out_anim->frame_count = read_u16(anim_data + 4);
    out_anim->frame_data_offset = read_u16(anim_data + 6);
    out_anim->flags = read_u16(anim_data + 8);
    out_anim->padding = read_u16(anim_data + 10);
    
    return 0;
}

int BLB_GetSpriteFrameMetadata(const u8* sprite_data, u16 frame_meta_offset,
                               u32 frame_index, SpriteFrame* out_frame) {
    const u8* frame_data;
    
    if (!sprite_data || !out_frame) {
        return -1;
    }
    
    /* Frame metadata is 36 bytes each */
    frame_data = sprite_data + frame_meta_offset + (frame_index * 36);
    
    out_frame->callback_id = read_u16(frame_data + 0);
    out_frame->padding1 = read_u16(frame_data + 2);
    out_frame->flip_flags = read_u16(frame_data + 4);
    out_frame->render_x = (s16)read_u16(frame_data + 6);
    out_frame->render_y = (s16)read_u16(frame_data + 8);
    out_frame->width = read_u16(frame_data + 10);
    out_frame->height = read_u16(frame_data + 12);
    out_frame->delay = read_u16(frame_data + 14);
    out_frame->padding2 = read_u16(frame_data + 16);
    out_frame->hitbox_x = (s16)read_u16(frame_data + 18);
    out_frame->hitbox_y = (s16)read_u16(frame_data + 20);
    out_frame->hitbox_w = read_u16(frame_data + 22);
    out_frame->hitbox_h = read_u16(frame_data + 24);
    out_frame->padding3 = read_u32(frame_data + 28);
    out_frame->rle_offset = read_u32(frame_data + 32);
    
    /* Sanity check dimensions */
    if (out_frame->width > 512 || out_frame->height > 512) {
        return -1;
    }
    
    return 0;
}

const u16* BLB_GetSpritePalette(const u8* sprite_data, u32 palette_offset) {
    if (!sprite_data) {
        return NULL;
    }
    
    /* Palette is 256 colors × 2 bytes = 512 bytes */
    return (const u16*)(sprite_data + palette_offset);
}

/* -----------------------------------------------------------------------------
 * BLB File Write Operations
 * -------------------------------------------------------------------------- */

BLBFile* BLB_Create(u8 level_count) {
    BLBFile* blb;
    u32 total_size;
    
    if (level_count == 0 || level_count > BLB_MAX_LEVELS) {
        return NULL;
    }
    
    blb = (BLBFile*)calloc(1, sizeof(BLBFile));
    if (!blb) {
        return NULL;
    }
    
    /* Allocate initial space: header + some sectors */
    /* Start with 64MB which should be plenty for most BLB files */
    total_size = 64 * 1024 * 1024;
    blb->data = (u8*)calloc(1, total_size);
    if (!blb->data) {
        free(blb);
        return NULL;
    }
    
    blb->size = total_size;
    blb->header = blb->data;
    blb->level_count = level_count;
    blb->movie_count = 0;
    blb->sector_count = 0;
    blb->is_jp = 0;  /* Default to PAL layout */
    
    /* Write counts to header */
    blb->header[BLB_OFF_LEVEL_COUNT] = level_count;
    blb->header[BLB_OFF_MOVIE_COUNT] = 0;
    blb->header[BLB_OFF_SECTOR_COUNT] = 0;
    
    return blb;
}

int BLB_SetLevelMetadata(BLBFile* blb, u8 level_index,
                         const char* level_id, const char* level_name,
                         u16 stage_count) {
    u8* entry;
    int i;
    
    if (!blb || !level_id || !level_name) {
        return -1;
    }
    
    if (level_index >= blb->level_count) {
        return -1;
    }
    
    if (stage_count == 0 || stage_count > BLB_MAX_STAGES) {
        return -1;
    }
    
    /* Get level entry */
    entry = blb->header + BLB_OFF_LEVEL_TABLE + (level_index * BLB_LEVEL_ENTRY_SIZE);
    
    /* Write level ID (4 chars + null) */
    memset(entry + LEVEL_OFF_LEVEL_ID, 0, 5);
    for (i = 0; i < 4 && level_id[i]; i++) {
        entry[LEVEL_OFF_LEVEL_ID + i] = (u8)level_id[i];
    }
    
    /* Write level name (max 20 chars + null) */
    memset(entry + LEVEL_OFF_LEVEL_NAME, 0, 21);
    for (i = 0; i < 20 && level_name[i]; i++) {
        entry[LEVEL_OFF_LEVEL_NAME + i] = (u8)level_name[i];
    }
    
    /* Write stage count */
    entry[LEVEL_OFF_STAGE_COUNT + 0] = (u8)(stage_count & 0xFF);
    entry[LEVEL_OFF_STAGE_COUNT + 1] = (u8)((stage_count >> 8) & 0xFF);
    
    return 0;
}

int BLB_WriteSegment(BLBFile* blb, u8 level_index, u8 stage_index,
                     const u8* segment_data, u32 segment_size,
                     u8 segment_type) {
    (void)blb;
    (void)level_index;
    (void)stage_index;
    (void)segment_data;
    (void)segment_size;
    (void)segment_type;
    
    /* TODO: Implement segment writing
     * This needs to:
     * 1. Find next available sector
     * 2. Write segment data to sectors
     * 3. Update level entry with sector offset/count
     * 4. Update BLB file size if needed
     */
    return -1;
}

int BLB_WriteToFile(const BLBFile* blb, const char* path) {
    FILE* f;
    
    if (!blb || !path || !blb->data) {
        return -1;
    }
    
    f = fopen(path, "wb");
    if (!f) {
        return -1;
    }
    
    /* Write entire BLB data */
    if (fwrite(blb->data, 1, blb->size, f) != blb->size) {
        fclose(f);
        return -1;
    }
    
    fclose(f);
    return 0;
}

/* -----------------------------------------------------------------------------
 * Segment Building Helpers
 * -------------------------------------------------------------------------- */

int BLB_SegmentBuilder_Init(SegmentBuilder* builder) {
    if (!builder) {
        return -1;
    }
    
    memset(builder, 0, sizeof(SegmentBuilder));
    
    /* Allocate initial capacity */
    builder->capacity = 32;
    builder->entries = (TOCEntry*)calloc(builder->capacity, sizeof(TOCEntry));
    if (!builder->entries) {
        return -1;
    }
    
    builder->data_capacity = 1024 * 1024;  /* 1MB initial */
    builder->data = (u8*)malloc(builder->data_capacity);
    if (!builder->data) {
        free(builder->entries);
        return -1;
    }
    
    builder->asset_count = 0;
    builder->data_size = 0;
    
    return 0;
}

int BLB_SegmentBuilder_AddAsset(SegmentBuilder* builder, u32 asset_id,
                                const u8* data, u32 size) {
    u32 offset;
    
    if (!builder || !data) {
        return -1;
    }
    
    /* Ensure capacity */
    if (builder->asset_count >= builder->capacity) {
        u32 new_cap = builder->capacity * 2;
        TOCEntry* new_entries = (TOCEntry*)realloc(builder->entries, 
                                                   new_cap * sizeof(TOCEntry));
        if (!new_entries) {
            return -1;
        }
        builder->entries = new_entries;
        builder->capacity = new_cap;
    }
    
    /* Calculate offset in segment (after TOC) */
    /* TOC is: u32 count + TOCEntry array */
    offset = 4 + (builder->asset_count + 1) * sizeof(TOCEntry);
    
    /* Ensure data capacity */
    while (builder->data_size + size > builder->data_capacity) {
        u32 new_cap = builder->data_capacity * 2;
        u8* new_data = (u8*)realloc(builder->data, new_cap);
        if (!new_data) {
            return -1;
        }
        builder->data = new_data;
        builder->data_capacity = new_cap;
    }
    
    /* Add TOC entry */
    builder->entries[builder->asset_count].id = asset_id;
    builder->entries[builder->asset_count].size = size;
    builder->entries[builder->asset_count].offset = offset + builder->data_size;
    
    /* Copy data */
    memcpy(builder->data + builder->data_size, data, size);
    builder->data_size += size;
    builder->asset_count++;
    
    return 0;
}

u8* BLB_SegmentBuilder_Finalize(SegmentBuilder* builder, u32* out_size) {
    u8* segment;
    u32 total_size;
    u32 toc_size;
    u32 i;
    
    if (!builder || !out_size) {
        return NULL;
    }
    
    /* Calculate total size */
    toc_size = 4 + builder->asset_count * sizeof(TOCEntry);
    total_size = toc_size + builder->data_size;
    
    /* Allocate final segment */
    segment = (u8*)malloc(total_size);
    if (!segment) {
        return NULL;
    }
    
    /* Write TOC count */
    segment[0] = (u8)(builder->asset_count & 0xFF);
    segment[1] = (u8)((builder->asset_count >> 8) & 0xFF);
    segment[2] = (u8)((builder->asset_count >> 16) & 0xFF);
    segment[3] = (u8)((builder->asset_count >> 24) & 0xFF);
    
    /* Write TOC entries */
    for (i = 0; i < builder->asset_count; i++) {
        u8* entry = segment + 4 + i * sizeof(TOCEntry);
        const TOCEntry* src = &builder->entries[i];
        
        /* Write as little-endian */
        entry[0] = (u8)(src->id & 0xFF);
        entry[1] = (u8)((src->id >> 8) & 0xFF);
        entry[2] = (u8)((src->id >> 16) & 0xFF);
        entry[3] = (u8)((src->id >> 24) & 0xFF);
        
        entry[4] = (u8)(src->size & 0xFF);
        entry[5] = (u8)((src->size >> 8) & 0xFF);
        entry[6] = (u8)((src->size >> 16) & 0xFF);
        entry[7] = (u8)((src->size >> 24) & 0xFF);
        
        entry[8] = (u8)(src->offset & 0xFF);
        entry[9] = (u8)((src->offset >> 8) & 0xFF);
        entry[10] = (u8)((src->offset >> 16) & 0xFF);
        entry[11] = (u8)((src->offset >> 24) & 0xFF);
    }
    
    /* Copy asset data */
    memcpy(segment + toc_size, builder->data, builder->data_size);
    
    *out_size = total_size;
    return segment;
}

void BLB_SegmentBuilder_Free(SegmentBuilder* builder) {
    if (!builder) return;
    
    if (builder->entries) {
        free(builder->entries);
        builder->entries = NULL;
    }
    
    if (builder->data) {
        free(builder->data);
        builder->data = NULL;
    }
    
    builder->asset_count = 0;
    builder->capacity = 0;
    builder->data_size = 0;
    builder->data_capacity = 0;
}
