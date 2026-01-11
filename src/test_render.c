/**
 * test_render.c - Test rendering functions
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "blb/blb.h"
#include "level/level.h"
#include "render/render.h"

/* Simple PPM writer for visualization */
static void write_ppm(const char* filename, const u8* rgba, int width, int height) {
    FILE* f = fopen(filename, "wb");
    if (!f) return;
    fprintf(f, "P6\n%d %d\n255\n", width, height);
    for (int i = 0; i < width * height; i++) {
        fputc(rgba[i * 4 + 0], f);  /* R */
        fputc(rgba[i * 4 + 1], f);  /* G */
        fputc(rgba[i * 4 + 2], f);  /* B */
    }
    fclose(f);
}

int main(int argc, char** argv) {
    BLBFile blb;
    LevelContext ctx;
    const char* blb_path = "../disks/blb/GAME.BLB";
    u8 rgba_16x16[16 * 16 * 4];
    u8 rgba_8x8[8 * 8 * 4];
    int width, height;
    int tile_index;
    int ret;
    
    if (argc > 1) {
        blb_path = argv[1];
    }
    
    printf("=== Evil Engine Render Test ===\n");
    
    /* Load BLB */
    ret = BLB_Open(blb_path, &blb);
    if (ret != 0) {
        printf("Error: Failed to open BLB file: %s\n", blb_path);
        return 1;
    }
    printf("BLB: %d levels loaded\n", blb.level_count);
    
    /* Load first level */
    Level_Init(&ctx);
    ret = Level_Load(&ctx, &blb, 0, 0);
    if (ret != 0) {
        printf("Error: Failed to load level\n");
        BLB_Close(&blb);
        return 1;
    }
    
    printf("\n--- Level Info ---\n");
    printf("Size: %dx%d tiles\n", ctx.tile_header->level_width, ctx.tile_header->level_height);
    printf("Total tiles: %u\n", ctx.total_tiles);
    printf("  16x16: %u\n", ctx.tile_header->count_16x16);
    printf("  8x8: %u\n", ctx.tile_header->count_8x8);
    printf("  Extra: %u\n", ctx.tile_header->count_extra);
    printf("Layers: %u\n", ctx.layer_count);
    printf("Entities: %u\n", ctx.entity_count);
    
    /* Test GetTotalTileCount */
    printf("\n--- Testing Accessors ---\n");
    printf("GetTotalTileCount: %u\n", GetTotalTileCount(&ctx));
    printf("GetTileHeaderPtr: %s\n", GetTileHeaderPtr(&ctx) ? "OK" : "NULL");
    
    /* Test tile rendering */
    printf("\n--- Rendering Tiles ---\n");
    
    /* Render first 16x16 tile */
    tile_index = 1;  /* tile_index is 1-based */
    ret = RenderTileToRGBA(&ctx, tile_index, rgba_16x16, &width, &height);
    if (ret == 0) {
        printf("Tile %d: %dx%d rendered OK\n", tile_index, width, height);
        write_ppm("/tmp/tile_16x16.ppm", rgba_16x16, width, height);
        printf("  Saved to /tmp/tile_16x16.ppm\n");
    } else {
        printf("Tile %d: render failed\n", tile_index);
    }
    
    /* Render first 8x8 tile (after all 16x16 tiles) */
    tile_index = ctx.tile_header->count_16x16 + 1;
    if (tile_index <= (int)ctx.total_tiles) {
        ret = RenderTileToRGBA(&ctx, tile_index, rgba_8x8, &width, &height);
        if (ret == 0) {
            printf("Tile %d (8x8): %dx%d rendered OK\n", tile_index, width, height);
            write_ppm("/tmp/tile_8x8.ppm", rgba_8x8, width, height);
            printf("  Saved to /tmp/tile_8x8.ppm\n");
        } else {
            printf("Tile %d (8x8): render failed\n", tile_index);
        }
    }
    
    /* Test palette access */
    printf("\n--- Palette Test ---\n");
    if (ctx.palette_indices && ctx.total_tiles > 0) {
        u8 pal_idx = ctx.palette_indices[0];
        const u16* palette = GetPaletteDataPtr(&ctx, pal_idx);
        if (palette) {
            printf("Palette %d: first 4 colors = [%04X %04X %04X %04X]\n",
                   pal_idx, palette[0], palette[1], palette[2], palette[3]);
        } else {
            printf("Palette %d: NULL\n", pal_idx);
        }
    }
    
    /* Test tilemap access */
    printf("\n--- Tilemap Test ---\n");
    if (ctx.layer_count > 0) {
        const u16* tilemap = GetTilemapDataPtr(&ctx, 0);
        if (tilemap) {
            printf("Layer 0 tilemap: first 8 entries = [%u %u %u %u %u %u %u %u]\n",
                   tilemap[0], tilemap[1], tilemap[2], tilemap[3],
                   tilemap[4], tilemap[5], tilemap[6], tilemap[7]);
        } else {
            printf("Layer 0 tilemap: NULL\n");
        }
    }
    
    Level_Unload(&ctx);
    BLB_Close(&blb);
    
    printf("\n=== Render Test Complete ===\n");
    return 0;
}
