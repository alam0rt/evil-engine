/**
 * test_level_view.c - Render a full level to PPM image
 * 
 * This test verifies the complete rendering pipeline by producing
 * a visual output that can be compared against the original game.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "blb/blb.h"
#include "level/level.h"
#include "render/render.h"

/* Render a single layer to an RGBA buffer */
static void render_layer(const LevelContext* ctx, u32 layer_index,
                         u8* rgba, int img_width, int img_height) {
    const u16* tilemap;
    const LayerEntry* layer;
    u32 lw, lh;
    u32 tx, ty;
    u8 tile_rgba[16 * 16 * 4];
    int tile_w, tile_h;
    
    layer = Level_GetLayer(ctx, layer_index);
    if (!layer) return;
    
    tilemap = GetTilemapDataPtr(ctx, layer_index);
    if (!tilemap) return;
    
    lw = layer->width;
    lh = layer->height;
    
    printf("  Layer %u: %ux%u tiles\n", layer_index, lw, lh);
    
    for (ty = 0; ty < lh && (ty * 16) < (u32)img_height; ty++) {
        for (tx = 0; tx < lw && (tx * 16) < (u32)img_width; tx++) {
            u16 tile_entry;
            u16 tile_index;
            int px, py;
            int x, y;
            
            tile_entry = tilemap[ty * lw + tx];
            tile_index = tile_entry & 0x7FF;  /* bits 0-10 */
            
            if (tile_index == 0) continue;  /* transparent */
            
            /* Render tile to temporary buffer */
            if (RenderTileToRGBA(ctx, tile_index, tile_rgba, &tile_w, &tile_h) != 0) {
                continue;
            }
            
            /* Copy to output image */
            px = tx * 16;
            py = ty * 16;
            
            for (y = 0; y < tile_h && (py + y) < img_height; y++) {
                for (x = 0; x < tile_w && (px + x) < img_width; x++) {
                    int src_idx = (y * tile_w + x) * 4;
                    int dst_idx = ((py + y) * img_width + (px + x)) * 4;
                    u8 a = tile_rgba[src_idx + 3];
                    
                    /* Skip fully transparent pixels (color index 0) */
                    if (a == 0) continue;
                    
                    /* Copy RGB */
                    rgba[dst_idx + 0] = tile_rgba[src_idx + 0];
                    rgba[dst_idx + 1] = tile_rgba[src_idx + 1];
                    rgba[dst_idx + 2] = tile_rgba[src_idx + 2];
                    rgba[dst_idx + 3] = 255;
                }
            }
        }
    }
}

static void write_ppm(const char* filename, const u8* rgba, int width, int height) {
    FILE* f = fopen(filename, "wb");
    if (!f) {
        printf("Error: Cannot write to %s\n", filename);
        return;
    }
    fprintf(f, "P6\n%d %d\n255\n", width, height);
    for (int i = 0; i < width * height; i++) {
        fputc(rgba[i * 4 + 0], f);
        fputc(rgba[i * 4 + 1], f);
        fputc(rgba[i * 4 + 2], f);
    }
    fclose(f);
    printf("Saved: %s (%dx%d)\n", filename, width, height);
}

int main(int argc, char** argv) {
    BLBFile blb;
    LevelContext ctx;
    const char* blb_path = "/home/sam/projects/btm/disks/blb/GAME.BLB";
    int level_index = 0;  /* SCIE */
    int stage_index = 0;
    u8* rgba;
    int img_width, img_height;
    u32 layer;
    int ret;
    
    if (argc > 1) blb_path = argv[1];
    if (argc > 2) level_index = atoi(argv[2]);
    if (argc > 3) stage_index = atoi(argv[3]);
    
    printf("=== Level Viewer Test ===\n");
    printf("BLB: %s\n", blb_path);
    printf("Level: %d, Stage: %d\n\n", level_index, stage_index);
    
    /* Load BLB */
    ret = BLB_Open(blb_path, &blb);
    if (ret != 0) {
        printf("Error: Failed to open BLB\n");
        return 1;
    }
    printf("Levels: %d\n", blb.level_count);
    printf("Level name: %s\n", BLB_GetLevelName(&blb, level_index));
    
    /* Load level */
    Level_Init(&ctx);
    ret = Level_Load(&ctx, &blb, level_index, stage_index);
    if (ret != 0) {
        printf("Error: Failed to load level\n");
        BLB_Close(&blb);
        return 1;
    }
    
    printf("\n--- Level Info ---\n");
    printf("Size: %dx%d tiles (%dx%d pixels)\n",
           ctx.tile_header->level_width, ctx.tile_header->level_height,
           ctx.tile_header->level_width * 16, ctx.tile_header->level_height * 16);
    printf("Tiles: %u (16x16=%u, 8x8=%u)\n",
           ctx.total_tiles, ctx.tile_header->count_16x16, ctx.tile_header->count_8x8);
    printf("Layers: %u\n", ctx.layer_count);
    printf("Entities: %u\n", ctx.entity_count);
    printf("Spawn: (%u, %u) tiles\n", ctx.tile_header->spawn_x, ctx.tile_header->spawn_y);
    
    /* Allocate image buffer */
    img_width = ctx.tile_header->level_width * 16;
    img_height = ctx.tile_header->level_height * 16;
    
    /* Clamp to reasonable size for testing */
    if (img_width > 2048) img_width = 2048;
    if (img_height > 2048) img_height = 2048;
    
    rgba = (u8*)calloc(img_width * img_height * 4, 1);
    if (!rgba) {
        printf("Error: Out of memory\n");
        Level_Unload(&ctx);
        BLB_Close(&blb);
        return 1;
    }
    
    /* Fill with background color */
    {
        u8 bg_r, bg_g, bg_b;
        Level_GetBackgroundColor(&ctx, &bg_r, &bg_g, &bg_b);
        printf("Background: RGB(%d, %d, %d)\n", bg_r, bg_g, bg_b);
        
        for (int i = 0; i < img_width * img_height; i++) {
            rgba[i * 4 + 0] = bg_r;
            rgba[i * 4 + 1] = bg_g;
            rgba[i * 4 + 2] = bg_b;
            rgba[i * 4 + 3] = 255;
        }
    }
    
    /* Render layers from back to front */
    printf("\n--- Rendering Layers ---\n");
    for (layer = 0; layer < ctx.layer_count; layer++) {
        const LayerEntry* le = Level_GetLayer(&ctx, layer);
        if (le && le->layer_type != 3) {  /* type 3 = skip */
            render_layer(&ctx, layer, rgba, img_width, img_height);
        }
    }
    
    /* Save output */
    printf("\n--- Output ---\n");
    write_ppm("/tmp/level_view.ppm", rgba, img_width, img_height);
    
    /* Cleanup */
    free(rgba);
    Level_Unload(&ctx);
    BLB_Close(&blb);
    
    printf("\n=== Done ===\n");
    return 0;
}
