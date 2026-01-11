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
