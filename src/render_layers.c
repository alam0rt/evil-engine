/**
 * render_layers.c - Render each layer to separate images with metadata
 * 
 * Outputs:
 *   <output_dir>/layer_<N>.ppm - Each layer's image
 *   <output_dir>/metadata.txt  - Layer info (parallax, dimensions)
 * 
 * Usage: render_layers <blb_path> <level> <stage> <output_dir>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include "blb/blb.h"
#include "level/level.h"
#include "render/render.h"

static void write_rgba(const char* filename, const u8* rgba, int width, int height) {
    FILE* f = fopen(filename, "wb");
    if (!f) return;
    /* Simple RGBA format: "RGBA" magic, width, height as u32, then raw pixels */
    fputc('R', f); fputc('G', f); fputc('B', f); fputc('A', f);
    fputc((width >> 0) & 0xFF, f);
    fputc((width >> 8) & 0xFF, f);
    fputc((width >> 16) & 0xFF, f);
    fputc((width >> 24) & 0xFF, f);
    fputc((height >> 0) & 0xFF, f);
    fputc((height >> 8) & 0xFF, f);
    fputc((height >> 16) & 0xFF, f);
    fputc((height >> 24) & 0xFF, f);
    fwrite(rgba, 1, width * height * 4, f);
    fclose(f);
}

int main(int argc, char** argv) {
    BLBFile blb;
    LevelContext ctx;
    const char* blb_path;
    const char* output_dir;
    int level_index, stage_index;
    char path_buf[512];
    FILE* meta;
    int ret;
    
    if (argc < 5) {
        fprintf(stderr, "Usage: %s <blb_path> <level> <stage> <output_dir>\n", argv[0]);
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
    
    /* Write metadata file */
    snprintf(path_buf, sizeof(path_buf), "%s/metadata.txt", output_dir);
    meta = fopen(path_buf, "w");
    if (!meta) {
        fprintf(stderr, "Error: Cannot create metadata file\n");
        Level_Unload(&ctx);
        BLB_Close(&blb);
        return 1;
    }
    
    /* Header info */
    {
        u8 bg_r, bg_g, bg_b;
        s32 spawn_x, spawn_y;
        Level_GetBackgroundColor(&ctx, &bg_r, &bg_g, &bg_b);
        Level_GetSpawnPosition(&ctx, &spawn_x, &spawn_y);
        
        fprintf(meta, "level_name=%s\n", BLB_GetLevelName(&blb, level_index));
        fprintf(meta, "level_index=%d\n", level_index);
        fprintf(meta, "stage_index=%d\n", stage_index);
        fprintf(meta, "level_width=%d\n", ctx.tile_header->level_width * 16);
        fprintf(meta, "level_height=%d\n", ctx.tile_header->level_height * 16);
        fprintf(meta, "bg_r=%d\n", bg_r);
        fprintf(meta, "bg_g=%d\n", bg_g);
        fprintf(meta, "bg_b=%d\n", bg_b);
        fprintf(meta, "spawn_x=%d\n", (int)spawn_x);
        fprintf(meta, "spawn_y=%d\n", (int)spawn_y);
        fprintf(meta, "layer_count=%d\n", ctx.layer_count);
        fprintf(meta, "entity_count=%d\n", ctx.entity_count);
        fprintf(meta, "\n");
    }
    
    /* Output entity data */
    if (ctx.entities && ctx.entity_count > 0) {
        for (u32 i = 0; i < ctx.entity_count; i++) {
            const EntityDef* e = &ctx.entities[i];
            /* Skip empty/invalid entities */
            if (e->x1 == 0 && e->y1 == 0 && e->x2 == 0 && e->y2 == 0) continue;
            
            fprintf(meta, "[entity_%u]\n", i);
            fprintf(meta, "x1=%d\n", e->x1);
            fprintf(meta, "y1=%d\n", e->y1);
            fprintf(meta, "x2=%d\n", e->x2);
            fprintf(meta, "y2=%d\n", e->y2);
            fprintf(meta, "x_center=%d\n", e->x_center);
            fprintf(meta, "y_center=%d\n", e->y_center);
            fprintf(meta, "type=%d\n", e->entity_type);
            fprintf(meta, "variant=%d\n", e->variant);
            fprintf(meta, "layer=%d\n", e->layer);
            fprintf(meta, "\n");
        }
    }
    
    /* Render each layer */
    for (u32 layer_idx = 0; layer_idx < ctx.layer_count; layer_idx++) {
        const LayerEntry* layer = Level_GetLayer(&ctx, layer_idx);
        int layer_w, layer_h;
        u8* rgba;
        
        if (!layer) continue;
        
        /* Skip layers marked as type 3 */
        if (layer->layer_type == 3) {
            fprintf(meta, "[layer_%u]\n", layer_idx);
            fprintf(meta, "skip=1\n\n");
            continue;
        }
        
        /* Get layer dimensions */
        layer_w = layer->width * 16;
        layer_h = layer->height * 16;
        
        if (layer_w == 0 || layer_h == 0) continue;
        
        /* Write layer metadata */
        fprintf(meta, "[layer_%u]\n", layer_idx);
        fprintf(meta, "width=%d\n", layer_w);
        fprintf(meta, "height=%d\n", layer_h);
        fprintf(meta, "x_offset=%d\n", layer->x_offset * 16);  /* Convert tiles to pixels */
        fprintf(meta, "y_offset=%d\n", layer->y_offset * 16);  /* Convert tiles to pixels */
        fprintf(meta, "scroll_x=%u\n", layer->scroll_x);  /* 16.16 fixed: 0x10000=1.0 */
        fprintf(meta, "scroll_y=%u\n", layer->scroll_y);
        fprintf(meta, "layer_type=%d\n", layer->layer_type);
        fprintf(meta, "file=layer_%u.rgba\n\n", layer_idx);
        
        /* Allocate and render layer */
        rgba = (u8*)calloc(layer_w * layer_h * 4, 1);
        if (!rgba) continue;
        
        /* Render layer (transparent background) */
        RenderLayerToRGBA(&ctx, layer_idx, rgba, layer_w, layer_h);
        
        /* Write RGBA (preserves alpha for transparency) */
        snprintf(path_buf, sizeof(path_buf), "%s/layer_%u.rgba", output_dir, layer_idx);
        write_rgba(path_buf, rgba, layer_w, layer_h);
        
        printf("Layer %u: %dx%d (scroll: %.4f, %.4f)\n", 
               layer_idx, layer_w, layer_h,
               (float)layer->scroll_x / 65536.0f,
               (float)layer->scroll_y / 65536.0f);
        
        free(rgba);
    }
    
    fclose(meta);
    
    printf("Rendered %d layers to %s/\n", ctx.layer_count, output_dir);
    
    /* Cleanup */
    Level_Unload(&ctx);
    BLB_Close(&blb);
    
    return 0;
}
