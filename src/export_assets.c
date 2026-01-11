/**
 * export_assets.c - Export BLB assets as Godot-compatible resources
 * 
 * Outputs:
 *   <output_dir>/tiles.png       - Tile atlas (all tiles in a grid)
 *   <output_dir>/palettes.json   - Palette data as RGBA arrays
 *   <output_dir>/layers.json     - Layer info (dimensions, parallax, tilemaps)
 *   <output_dir>/entities.json   - Entity definitions
 *   <output_dir>/level_info.json - Level metadata (background color, spawn, etc.)
 * 
 * Usage: export_assets <blb_path> <level> <stage> <output_dir>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <math.h>
#include "blb/blb.h"
#include "level/level.h"
#include "render/render.h"

/* PNG writing - minimal implementation */
#include <stdint.h>

/* CRC32 for PNG chunks */
static uint32_t crc_table[256];
static int crc_table_computed = 0;

static void make_crc_table(void) {
    uint32_t c;
    int n, k;
    for (n = 0; n < 256; n++) {
        c = (uint32_t)n;
        for (k = 0; k < 8; k++) {
            if (c & 1)
                c = 0xedb88320L ^ (c >> 1);
            else
                c = c >> 1;
        }
        crc_table[n] = c;
    }
    crc_table_computed = 1;
}

static uint32_t update_crc(uint32_t crc, const uint8_t *buf, size_t len) {
    uint32_t c = crc;
    size_t n;
    if (!crc_table_computed) make_crc_table();
    for (n = 0; n < len; n++) {
        c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
    }
    return c;
}

static uint32_t crc32(const uint8_t *buf, size_t len) {
    return update_crc(0xffffffffL, buf, len) ^ 0xffffffffL;
}

/* Adler32 for zlib */
static uint32_t adler32(const uint8_t *data, size_t len) {
    uint32_t a = 1, b = 0;
    size_t i;
    for (i = 0; i < len; i++) {
        a = (a + data[i]) % 65521;
        b = (b + a) % 65521;
    }
    return (b << 16) | a;
}

/* Write PNG with RGBA data (uncompressed zlib - simple but works) */
static int write_png(const char* filename, const uint8_t* rgba, int width, int height) {
    FILE* f = fopen(filename, "wb");
    if (!f) return -1;
    
    /* PNG signature */
    const uint8_t sig[8] = {137, 80, 78, 71, 13, 10, 26, 10};
    fwrite(sig, 1, 8, f);
    
    /* IHDR chunk */
    {
        uint8_t ihdr[13];
        uint8_t chunk[4 + 13 + 4];
        uint32_t crc;
        
        ihdr[0] = (width >> 24) & 0xff;
        ihdr[1] = (width >> 16) & 0xff;
        ihdr[2] = (width >> 8) & 0xff;
        ihdr[3] = width & 0xff;
        ihdr[4] = (height >> 24) & 0xff;
        ihdr[5] = (height >> 16) & 0xff;
        ihdr[6] = (height >> 8) & 0xff;
        ihdr[7] = height & 0xff;
        ihdr[8] = 8;  /* bit depth */
        ihdr[9] = 6;  /* color type: RGBA */
        ihdr[10] = 0; /* compression */
        ihdr[11] = 0; /* filter */
        ihdr[12] = 0; /* interlace */
        
        /* Length */
        uint8_t len[4] = {0, 0, 0, 13};
        fwrite(len, 1, 4, f);
        
        /* Type + data */
        chunk[0] = 'I'; chunk[1] = 'H'; chunk[2] = 'D'; chunk[3] = 'R';
        memcpy(chunk + 4, ihdr, 13);
        fwrite(chunk, 1, 17, f);
        
        /* CRC */
        crc = crc32(chunk, 17);
        uint8_t crc_bytes[4] = {(crc >> 24) & 0xff, (crc >> 16) & 0xff, (crc >> 8) & 0xff, crc & 0xff};
        fwrite(crc_bytes, 1, 4, f);
    }
    
    /* IDAT chunk - use store (uncompressed) zlib blocks */
    {
        /* Build filtered image data: 1 filter byte per row + RGBA pixels */
        size_t row_bytes = 1 + width * 4;
        size_t raw_size = row_bytes * height;
        uint8_t* raw = (uint8_t*)malloc(raw_size);
        
        for (int y = 0; y < height; y++) {
            raw[y * row_bytes] = 0; /* No filter */
            memcpy(raw + y * row_bytes + 1, rgba + y * width * 4, width * 4);
        }
        
        /* Uncompressed zlib: header (2 bytes) + data blocks + adler32 (4 bytes) */
        /* For simplicity, use a single stored block if small enough, else multiple */
        size_t zlib_size = 2 + raw_size + 5 * ((raw_size + 65534) / 65535) + 4;
        uint8_t* zlib = (uint8_t*)malloc(zlib_size);
        size_t zp = 0;
        
        /* Zlib header: CMF=0x78, FLG=0x01 (no dict, low compression) */
        zlib[zp++] = 0x78;
        zlib[zp++] = 0x01;
        
        /* Stored blocks */
        size_t remaining = raw_size;
        size_t rp = 0;
        while (remaining > 0) {
            size_t block_size = remaining > 65535 ? 65535 : remaining;
            int is_final = (remaining <= 65535) ? 1 : 0;
            
            zlib[zp++] = is_final; /* BFINAL + BTYPE=00 (stored) */
            zlib[zp++] = block_size & 0xff;
            zlib[zp++] = (block_size >> 8) & 0xff;
            zlib[zp++] = ~block_size & 0xff;
            zlib[zp++] = (~block_size >> 8) & 0xff;
            
            memcpy(zlib + zp, raw + rp, block_size);
            zp += block_size;
            rp += block_size;
            remaining -= block_size;
        }
        
        /* Adler32 */
        uint32_t adler = adler32(raw, raw_size);
        zlib[zp++] = (adler >> 24) & 0xff;
        zlib[zp++] = (adler >> 16) & 0xff;
        zlib[zp++] = (adler >> 8) & 0xff;
        zlib[zp++] = adler & 0xff;
        
        free(raw);
        
        /* Write IDAT */
        uint8_t len[4] = {
            (zp >> 24) & 0xff,
            (zp >> 16) & 0xff,
            (zp >> 8) & 0xff,
            zp & 0xff
        };
        fwrite(len, 1, 4, f);
        
        uint8_t type[4] = {'I', 'D', 'A', 'T'};
        fwrite(type, 1, 4, f);
        fwrite(zlib, 1, zp, f);
        
        /* CRC of type + data */
        uint32_t crc = crc32(type, 4);
        crc = update_crc(crc ^ 0xffffffff, zlib, zp) ^ 0xffffffff;
        uint8_t crc_bytes[4] = {(crc >> 24) & 0xff, (crc >> 16) & 0xff, (crc >> 8) & 0xff, crc & 0xff};
        fwrite(crc_bytes, 1, 4, f);
        
        free(zlib);
    }
    
    /* IEND chunk */
    {
        uint8_t iend[12] = {0, 0, 0, 0, 'I', 'E', 'N', 'D', 0xae, 0x42, 0x60, 0x82};
        fwrite(iend, 1, 12, f);
    }
    
    fclose(f);
    return 0;
}

/* Export tile atlas - all tiles in a grid */
static int export_tile_atlas(const LevelContext* ctx, const char* output_dir) {
    char path[512];
    u32 total_tiles;
    int tiles_per_row;
    int atlas_width, atlas_height;
    u8* atlas_rgba;
    u32 tile_idx;
    u8 tile_rgba[16 * 16 * 4];
    int tile_w, tile_h;
    
    if (!ctx->tile_header) return -1;
    
    total_tiles = ctx->tile_header->count_16x16 + 
                  ctx->tile_header->count_8x8 + 
                  ctx->tile_header->count_extra;
    
    if (total_tiles == 0) return -1;
    
    /* Arrange tiles in a square-ish grid */
    tiles_per_row = (int)ceil(sqrt((double)total_tiles));
    if (tiles_per_row < 1) tiles_per_row = 1;
    
    atlas_width = tiles_per_row * 16;
    atlas_height = ((total_tiles + tiles_per_row - 1) / tiles_per_row) * 16;
    
    atlas_rgba = (u8*)calloc(atlas_width * atlas_height * 4, 1);
    if (!atlas_rgba) return -1;
    
    /* Render each tile to the atlas */
    for (tile_idx = 1; tile_idx <= total_tiles; tile_idx++) {
        int grid_x, grid_y;
        int px, py;
        int x, y;
        
        if (RenderTileToRGBA(ctx, tile_idx, tile_rgba, &tile_w, &tile_h) != 0) {
            continue;
        }
        
        grid_x = (tile_idx - 1) % tiles_per_row;
        grid_y = (tile_idx - 1) / tiles_per_row;
        px = grid_x * 16;
        py = grid_y * 16;
        
        /* Copy tile to atlas (centered if 8x8) */
        int offset_x = (16 - tile_w) / 2;
        int offset_y = (16 - tile_h) / 2;
        
        for (y = 0; y < tile_h; y++) {
            for (x = 0; x < tile_w; x++) {
                int src_idx = (y * tile_w + x) * 4;
                int dst_x = px + offset_x + x;
                int dst_y = py + offset_y + y;
                int dst_idx = (dst_y * atlas_width + dst_x) * 4;
                
                atlas_rgba[dst_idx + 0] = tile_rgba[src_idx + 0];
                atlas_rgba[dst_idx + 1] = tile_rgba[src_idx + 1];
                atlas_rgba[dst_idx + 2] = tile_rgba[src_idx + 2];
                atlas_rgba[dst_idx + 3] = tile_rgba[src_idx + 3];
            }
        }
    }
    
    /* Write PNG */
    snprintf(path, sizeof(path), "%s/tiles.png", output_dir);
    write_png(path, atlas_rgba, atlas_width, atlas_height);
    
    free(atlas_rgba);
    
    printf("Exported tile atlas: %dx%d (%u tiles)\n", atlas_width, atlas_height, total_tiles);
    return 0;
}

/* Export level info as JSON */
static int export_level_info(const LevelContext* ctx, const BLBFile* blb, 
                             int level_index, int stage_index, const char* output_dir) {
    char path[512];
    FILE* f;
    u8 bg_r, bg_g, bg_b;
    s32 spawn_x, spawn_y;
    u32 total_tiles;
    int tiles_per_row;
    
    snprintf(path, sizeof(path), "%s/level_info.json", output_dir);
    f = fopen(path, "w");
    if (!f) return -1;
    
    Level_GetBackgroundColor(ctx, &bg_r, &bg_g, &bg_b);
    Level_GetSpawnPosition(ctx, &spawn_x, &spawn_y);
    
    total_tiles = ctx->tile_header->count_16x16 + 
                  ctx->tile_header->count_8x8 + 
                  ctx->tile_header->count_extra;
    tiles_per_row = (int)ceil(sqrt((double)total_tiles));
    
    fprintf(f, "{\n");
    fprintf(f, "  \"level_name\": \"%s\",\n", BLB_GetLevelName(blb, level_index));
    fprintf(f, "  \"level_index\": %d,\n", level_index);
    fprintf(f, "  \"stage_index\": %d,\n", stage_index);
    fprintf(f, "  \"level_width\": %d,\n", ctx->tile_header->level_width);
    fprintf(f, "  \"level_height\": %d,\n", ctx->tile_header->level_height);
    fprintf(f, "  \"level_width_px\": %d,\n", ctx->tile_header->level_width * 16);
    fprintf(f, "  \"level_height_px\": %d,\n", ctx->tile_header->level_height * 16);
    fprintf(f, "  \"background_color\": [%d, %d, %d],\n", bg_r, bg_g, bg_b);
    fprintf(f, "  \"spawn_x\": %d,\n", (int)spawn_x);
    fprintf(f, "  \"spawn_y\": %d,\n", (int)spawn_y);
    fprintf(f, "  \"tile_count\": %u,\n", total_tiles);
    fprintf(f, "  \"tiles_per_row\": %d,\n", tiles_per_row);
    fprintf(f, "  \"layer_count\": %u,\n", ctx->layer_count);
    fprintf(f, "  \"entity_count\": %u\n", ctx->entity_count);
    fprintf(f, "}\n");
    
    fclose(f);
    return 0;
}

/* Export layers as JSON with embedded tilemaps */
static int export_layers(const LevelContext* ctx, const char* output_dir) {
    char path[512];
    FILE* f;
    u32 i;
    
    snprintf(path, sizeof(path), "%s/layers.json", output_dir);
    f = fopen(path, "w");
    if (!f) return -1;
    
    fprintf(f, "[\n");
    
    for (i = 0; i < ctx->layer_count; i++) {
        const LayerEntry* layer = Level_GetLayer(ctx, i);
        const u16* tilemap;
        u32 tilemap_size;
        u32 j;
        
        if (!layer) continue;
        
        fprintf(f, "  {\n");
        fprintf(f, "    \"index\": %u,\n", i);
        fprintf(f, "    \"width\": %d,\n", layer->width);
        fprintf(f, "    \"height\": %d,\n", layer->height);
        fprintf(f, "    \"x_offset\": %d,\n", layer->x_offset);
        fprintf(f, "    \"y_offset\": %d,\n", layer->y_offset);
        fprintf(f, "    \"scroll_x\": %.6f,\n", (float)layer->scroll_x / 65536.0f);
        fprintf(f, "    \"scroll_y\": %.6f,\n", (float)layer->scroll_y / 65536.0f);
        fprintf(f, "    \"layer_type\": %d,\n", layer->layer_type);
        fprintf(f, "    \"skip\": %s,\n", (layer->layer_type == 3) ? "true" : "false");
        
        /* Export tilemap as array */
        tilemap = GetTilemapDataPtr(ctx, i);
        tilemap_size = layer->width * layer->height;
        
        fprintf(f, "    \"tilemap\": [");
        if (tilemap && tilemap_size > 0) {
            for (j = 0; j < tilemap_size; j++) {
                if (j > 0) fprintf(f, ",");
                if (j % layer->width == 0) fprintf(f, "\n      ");
                fprintf(f, "%d", tilemap[j] & 0xFFF);  /* tile index only */
            }
            fprintf(f, "\n    ");
        }
        fprintf(f, "]\n");
        
        fprintf(f, "  }%s\n", (i < ctx->layer_count - 1) ? "," : "");
    }
    
    fprintf(f, "]\n");
    fclose(f);
    
    printf("Exported %u layers\n", ctx->layer_count);
    return 0;
}

/* Export entities as JSON */
static int export_entities(const LevelContext* ctx, const char* output_dir) {
    char path[512];
    FILE* f;
    u32 i;
    int first = 1;
    
    snprintf(path, sizeof(path), "%s/entities.json", output_dir);
    f = fopen(path, "w");
    if (!f) return -1;
    
    fprintf(f, "[\n");
    
    if (ctx->entities && ctx->entity_count > 0) {
        for (i = 0; i < ctx->entity_count; i++) {
            const EntityDef* e = &ctx->entities[i];
            
            /* Skip empty entities */
            if (e->x1 == 0 && e->y1 == 0 && e->x2 == 0 && e->y2 == 0) continue;
            
            if (!first) fprintf(f, ",\n");
            first = 0;
            
            fprintf(f, "  {\n");
            fprintf(f, "    \"id\": %u,\n", i);
            fprintf(f, "    \"x1\": %d,\n", e->x1);
            fprintf(f, "    \"y1\": %d,\n", e->y1);
            fprintf(f, "    \"x2\": %d,\n", e->x2);
            fprintf(f, "    \"y2\": %d,\n", e->y2);
            fprintf(f, "    \"x_center\": %d,\n", e->x_center);
            fprintf(f, "    \"y_center\": %d,\n", e->y_center);
            fprintf(f, "    \"type\": %d,\n", e->entity_type);
            fprintf(f, "    \"variant\": %d,\n", e->variant);
            fprintf(f, "    \"layer\": %d\n", e->layer);
            fprintf(f, "  }");
        }
    }
    
    fprintf(f, "\n]\n");
    fclose(f);
    
    printf("Exported %u entities\n", ctx->entity_count);
    return 0;
}

int main(int argc, char** argv) {
    BLBFile blb;
    LevelContext ctx;
    const char* blb_path;
    const char* output_dir;
    int level_index, stage_index;
    int ret;
    
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <blb_path> <level> <stage> <output_dir>\n", argv[0]);
        fprintf(stderr, "\nExports BLB level assets as Godot-compatible resources:\n");
        fprintf(stderr, "  tiles.png       - Tile atlas\n");
        fprintf(stderr, "  level_info.json - Level metadata\n");
        fprintf(stderr, "  layers.json     - Layer data with tilemaps\n");
        fprintf(stderr, "  entities.json   - Entity definitions\n");
        return 1;
    }
    
    blb_path = argv[1];
    level_index = atoi(argv[2]);
    stage_index = atoi(argv[3]);
    output_dir = argv[4];
    
    /* Create output directory */
    mkdir(output_dir, 0755);
    
    /* Load BLB */
    ret = BLB_Open(blb_path, &blb);
    if (ret != 0) {
        fprintf(stderr, "Error: Failed to open BLB: %s\n", blb_path);
        return 1;
    }
    
    /* Load level */
    Level_Init(&ctx);
    ret = Level_Load(&ctx, &blb, level_index, stage_index);
    if (ret != 0) {
        fprintf(stderr, "Error: Failed to load level %d stage %d\n", level_index, stage_index);
        BLB_Close(&blb);
        return 1;
    }
    
    printf("Exporting: %s (level %d, stage %d)\n", 
           BLB_GetLevelName(&blb, level_index), level_index, stage_index);
    
    /* Export all assets */
    export_tile_atlas(&ctx, output_dir);
    export_level_info(&ctx, &blb, level_index, stage_index, output_dir);
    export_layers(&ctx, output_dir);
    export_entities(&ctx, output_dir);
    
    printf("Done! Assets exported to: %s/\n", output_dir);
    
    /* Cleanup */
    Level_Unload(&ctx);
    BLB_Close(&blb);
    
    return 0;
}
