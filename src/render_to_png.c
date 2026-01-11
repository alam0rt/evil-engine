/**
 * render_to_png.c - Render level to PNG file for Godot to load
 * 
 * Usage: render_to_png <blb_path> <level> <stage> <output.png>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "blb/blb.h"
#include "level/level.h"
#include "render/render.h"

/* Minimal PNG writer (uncompressed) - for simplicity */
static void write_ppm(const char* filename, const u8* rgba, int width, int height) {
    FILE* f = fopen(filename, "wb");
    if (!f) return;
    fprintf(f, "P6\n%d %d\n255\n", width, height);
    for (int i = 0; i < width * height; i++) {
        fputc(rgba[i * 4 + 0], f);
        fputc(rgba[i * 4 + 1], f);
        fputc(rgba[i * 4 + 2], f);
    }
    fclose(f);
}

int main(int argc, char** argv) {
    BLBFile blb;
    LevelContext ctx;
    const char* blb_path;
    const char* output_path;
    int level_index, stage_index;
    u8* rgba;
    int img_width, img_height;
    int ret;
    
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <blb_path> <level> <stage> <output.ppm>\n", argv[0]);
        return 1;
    }
    
    blb_path = argv[1];
    level_index = atoi(argv[2]);
    stage_index = atoi(argv[3]);
    output_path = argv[4];
    
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
    
    /* Calculate dimensions (clamp to 4096 max) */
    img_width = ctx.tile_header->level_width * 16;
    img_height = ctx.tile_header->level_height * 16;
    if (img_width > 4096) img_width = 4096;
    if (img_height > 4096) img_height = 4096;
    
    /* Allocate and render */
    rgba = (u8*)calloc(img_width * img_height * 4, 1);
    if (!rgba) {
        fprintf(stderr, "Error: Out of memory\n");
        Level_Unload(&ctx);
        BLB_Close(&blb);
        return 1;
    }
    
    /* Fill background and render all layers */
    {
        u8 bg_r, bg_g, bg_b;
        u32 layer;
        
        Level_GetBackgroundColor(&ctx, &bg_r, &bg_g, &bg_b);
        for (int i = 0; i < img_width * img_height; i++) {
            rgba[i * 4 + 0] = bg_r;
            rgba[i * 4 + 1] = bg_g;
            rgba[i * 4 + 2] = bg_b;
            rgba[i * 4 + 3] = 255;
        }
        
        for (layer = 0; layer < ctx.layer_count; layer++) {
            const LayerEntry* le = Level_GetLayer(&ctx, layer);
            if (le && le->layer_type != 3) {
                RenderLayerToRGBA(&ctx, layer, rgba, img_width, img_height);
            }
        }
    }
    
    /* Write output */
    write_ppm(output_path, rgba, img_width, img_height);
    printf("Rendered: %s (%dx%d)\n", output_path, img_width, img_height);
    
    /* Cleanup */
    free(rgba);
    Level_Unload(&ctx);
    BLB_Close(&blb);
    
    return 0;
}
