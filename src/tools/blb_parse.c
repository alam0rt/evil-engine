#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/* 
// PSYQ int types
typedef signed char int8_t;

typedef short int16_t;

typedef int int32_t;

typedef long long int64_t;

typedef unsigned char uint8_t;

typedef unsigned short uint16_t;

typedef unsigned int uint32_t;

typedef unsigned long long uint64_t; 
*/

#define SECTOR_SIZE 0x1000
#define HEADER_SIZE 2 * SECTOR_SIZE

#define LEVEL_OFFSET 0x0
#define LEVEL_SIZE 0xB60

typedef struct {
    uint16_t primary_sector_offset;
    uint16_t primary_sector_count;
    uint32_t primary_buffer_size;
    uint32_t entry1_offset;
    uint8_t asset_index; // 0-25
    uint8_t password_flag;

    // Stage configuration
    uint16_t stage_count;
    uint16_t tertiary_data_offset[6];
    uint16_t _stage_pad1;
    
    // Secondary sectors
    uint16_t secondary_sector_offset[6];
    uint16_t _secondary_pad1;
    uint16_t secondary_sector_count[6];
    uint16_t _secondary_pad2;

    // Tertiary sectors
    uint16_t tertiary_sector_offset[6];
    uint16_t _tertiary_pad1;
    uint16_t tertiary_sector_count[6];
    uint16_t _tertiary_pad2;

    // Level identification
    char level_id[5];
    char level_name[21];
} LevelEntry;

typedef struct {
    // 0x1000 bytes
    LevelEntry level_entries[LEVEL_SIZE / sizeof(LevelEntry)];
    unsigned char data[HEADER_SIZE - sizeof(LevelEntry) * (LEVEL_SIZE / sizeof(LevelEntry))];
} BLBHeader;

typedef struct {
    BLBHeader header;
    unsigned char* data;
} BLBFile;

static inline unsigned char* blb_get(const BLBFile* blb, size_t size, size_t offset) {
    printf("blb_get: offset=0x%04zX, size=0x%04zX\n", offset, size);
    return (unsigned char*)blb + offset;
}

void hex_dump_bytes(const void* data, size_t size, size_t offset, size_t count, const char* name) {
    size_t width = size / count;

    printf("name: %s\n", name);
    printf("size: %X (%zu) bytes\n", (int)size, size);
    printf("count: %X (%zu) entries\n", (int)count, count);
    printf("width: %X (%zu) bytes per entry\n", (int)width, width);

    for (size_t i = 0; i < count; i++) {
        printf("%02X ", ((unsigned char*)data)[offset + i]);
        if (i % width == width-1) {
            printf("\n");
        }
    }
    printf("\n");
}

static int open_blb_file(const char* path, BLBFile** out_blb) {
    BLBFile* blb;
    FILE* result;
    
    /* Allocate BLBFile structure */
    blb = (BLBFile*)calloc(1, sizeof(BLBFile));
    if (!blb) {
        fprintf(stderr, "Error: Failed to allocate BLBFile structure\n");
        return -1;
    }

    result = fopen(path, "rb");
    if (!result) {
        fprintf(stderr, "Error: Failed to open file '%s': %s\n", path, strerror(errno));
        free(blb);
        return -1;
    }

    fread(blb, 1, sizeof(BLBFile), result);
    fclose(result);
    
    *out_blb = blb;
    return 0;
}

int main(int argc, char** argv) {
    BLBFile* blb = NULL;
    const char* path;
    
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <path/to/GAME.BLB>\n", argv[0]);
        return 1;
    }
    
    path = argv[1];
    
    printf("Opening BLB file: %s\n", path);
    printf("----------------------------------------\n\n");
    

    if (open_blb_file(path, &blb) != 0) {
        return 1;
    }
    
    /* Print basic file info */
    printf("BLB File opened successfully:\n");
    hex_dump_bytes(blb,  0xB60, 0x0, 0x70, "levels");

    printf("level_entries:\n");
    for (size_t i = 0; i < 26; i++) {
        printf("level_entry %d:\n", i);
        printf("\tprimary_sector_offset: %X\n", blb->header.level_entries[i].primary_sector_offset);
        printf("\tprimary_sector_count: %X\n", blb->header.level_entries[i].primary_sector_count);
        printf("\tprimary_buffer_size: %X\n", blb->header.level_entries[i].primary_buffer_size);
        printf("\tentry1_offset: %X\n", blb->header.level_entries[i].entry1_offset);
        printf("\tasset_index: %X\n", blb->header.level_entries[i].asset_index);
        printf("\tpassword_flag: %X\n", blb->header.level_entries[i].password_flag);
        printf("\tstage_count: %X\n", blb->header.level_entries[i].stage_count);
        printf("\tsecondary_sector_offset: %X\n", blb->header.level_entries[i].secondary_sector_offset[0]);
        printf("\tsecondary_sector_count: %X\n", blb->header.level_entries[i].secondary_sector_count[0]);
        printf("\ttertiary_sector_offset: %X\n", blb->header.level_entries[i].tertiary_sector_offset[0]);
        printf("\ttertiary_sector_count: %X\n", blb->header.level_entries[i].tertiary_sector_count[0]);
        printf("\tlevel_id: %s\n", blb->header.level_entries[i].level_id);
        printf("\tlevel_name: %s\n", blb->header.level_entries[i].level_name);
        printf("\n");
    }

    /*
    unsigned char* data = blb_get(blb, LEVEL_SIZE, LEVEL_OFFSET);
    size_t entry_size = 0x6F;
    size_t entry_count = LEVEL_SIZE / entry_size;
    printf("entry_size: %X (%zu) bytes\n", (int)entry_size, entry_size);
    printf("entry_count: %X (%zu) entries\n", (int)entry_count, entry_count);
    printf("\ndata:\n");
    for (size_t i = 0; i < entry_count; i++) {
        printf("entry %d:\n", i);
        for (size_t j = 0; j < entry_size; j++) {
            printf("%02X ", data[i * entry_size + j]);
        }
        printf("\n");
    }
    */
    
    // Clean up
    free(blb);
    
    printf("Done!\n");
    return 0;
}

