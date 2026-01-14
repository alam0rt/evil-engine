#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
// JSON writer
#include <stdarg.h>

typedef struct {
    FILE* out;
    int indent;
    int needs_comma;
} JsonWriter;

static void json_write(JsonWriter* w, const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vfprintf(w->out, fmt, args);
    va_end(args);
}

static void json_newline_indent(JsonWriter* w) {
    fprintf(w->out, "\n");
    for (int i = 0; i < w->indent; i++) fprintf(w->out, "  ");
}

static void json_begin_obj(JsonWriter* w, const char* key) {
    if (w->needs_comma) fprintf(w->out, ",");
    json_newline_indent(w);
    if (key) fprintf(w->out, "\"%s\": {", key);
    else fprintf(w->out, "{");
    w->indent++;
    w->needs_comma = 0;
}

static void json_end_obj(JsonWriter* w) {
    w->indent--;
    json_newline_indent(w);
    fprintf(w->out, "}");
    w->needs_comma = 1;
}

static void json_field_str(JsonWriter* w, const char* key, const char* value) {
    if (w->needs_comma) fprintf(w->out, ",");
    json_newline_indent(w);
    fprintf(w->out, "\"%s\": \"%s\"", key, value);
    w->needs_comma = 1;
}

static void json_field_hex(JsonWriter* w, const char* key, unsigned int value) {
    if (w->needs_comma) fprintf(w->out, ",");
    json_newline_indent(w);
    fprintf(w->out, "\"%s\": \"0x%X\"", key, value);
    w->needs_comma = 1;
}

static void json_field_int(JsonWriter* w, const char* key, int value) {
    if (w->needs_comma) fprintf(w->out, ",");
    json_newline_indent(w);
    fprintf(w->out, "\"%s\": %d", key, value);
    w->needs_comma = 1;
}
// END JSON WRITER

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
    uint16_t reserved; // always 0
    uint16_t sector_count;
    char name[5]; // was ID before
    char id[3];
    char path[16];
} MovieEntry;

typedef struct {
    uint8_t level_index;
    uint8_t flags;
    uint8_t display_timeout_sec;
    char code[5];
    char short_name[4];
    uint16_t sector_offset;
    uint16_t sector_count;
} SectorTableEntry;

typedef struct {
    uint16_t sector_offset;
    uint16_t sector_count;
} Mode6SectorTableEntry;

typedef struct {
    char code[5];
    uint8_t _pad[3];
    uint16_t sector_offset;
    uint16_t sector_count;
} CreditsSequenceEntry;
typedef struct {
    uint8_t mode[26]; // 26 levels?
    uint8_t index[26];
} PlaybackSequenceEntry;

#define SECTOR_SIZE 0x1000
#define HEADER_SIZE 2 * SECTOR_SIZE

#define LEVEL_OFFSET 0x0
#define LEVEL_SIZE 0xB60
#define LEVEL_COUNT 26

#define MOVIE_OFFSET LEVEL_SIZE
#define MOVIE_SIZE 0x168
#define MOVIE_COUNT 13

#define SECTOR_TABLE_OFFSET 0xCD0
#define SECTOR_TABLE_SIZE 0x200
#define SECTOR_TABLE_COUNT 32

#define MODE6_SECTOR_TABLE_OFFSET 0xECC
#define MODE6_SECTOR_TABLE_SIZE 0x44
#define MODE6_SECTOR_TABLE_COUNT 17

#define CREDITS_SEQUENCE_OFFSET 0xF10
#define CREDITS_SEQUENCE_SIZE 0x21
#define CREDITS_SEQUENCE_COUNT 2

#define PLAYBACK_SEQUENCE_OFFSET 0xF34
#define PLAYBACK_SEQUENCE_SIZE 0xCC
#define PLAYBACK_SEQUENCE_COUNT LEVEL_COUNT

typedef struct {
    // 0x1000 bytes
    LevelEntry level_entries[26];
    MovieEntry movie_table[13];
    uint16_t _pad1;
    SectorTableEntry sector_table[32];
    Mode6SectorTableEntry mode6_sector_table[17];
    CreditsSequenceEntry credits_sequence_table[2];
    uint8_t level_count;
    uint8_t movie_count;
    uint8_t sector_table_entry_count;
    PlaybackSequenceEntry playback_sequence_table[26];
} BLBHeader;


typedef struct {
    BLBHeader header;
    unsigned char* data;
} BLBFile;

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

    fread(&blb->header, 1, sizeof(BLBHeader), result);
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

    JsonWriter w = {
        .out = stdout,
        .indent = 0,
        .needs_comma = 0,
    };

    json_begin_obj(&w, NULL);
    json_begin_obj(&w, "header");
    json_begin_obj(&w, "level_metadata_table");

    for (int i = 0; i <  blb->header.level_count; i++) {
        json_begin_obj(&w, NULL);
        json_field_int(&w, "primary_sector_offset", blb->header.level_entries[i].primary_sector_offset);
        json_field_int(&w, "primary_sector_count", blb->header.level_entries[i].primary_sector_count);
        json_field_int(&w, "primary_buffer_size", blb->header.level_entries[i].primary_buffer_size);
        json_field_int(&w, "entry1_offset", blb->header.level_entries[i].entry1_offset);
        json_field_int(&w, "asset_index", blb->header.level_entries[i].asset_index);
        json_field_int(&w, "password_flag", blb->header.level_entries[i].password_flag);

        json_field_int(&w, "stage_count", blb->header.level_entries[i].stage_count);
        for (int j = 0; j < 6; j++) {
            json_field_int(&w, "tertiary_data_offset", blb->header.level_entries[i].tertiary_data_offset[j]);
        }


        json_end_obj(&w);
    }
    json_field_int(&w, "level_count", blb->header.level_count);
    json_field_int(&w, "movie_count", blb->header.movie_count);
    json_field_int(&w, "sector_table_entry_count", blb->header.sector_table_entry_count);
    json_end_obj(&w);

    fprintf(w.out, "\n");

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

