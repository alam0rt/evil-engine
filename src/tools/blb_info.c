/**
 * blb_info.c - CLI tool to display BLB archive information
 * 
 * Usage: blb_info <path/to/GAME.BLB>
 * 
 * This tool demonstrates using the evil_engine library standalone
 * without any Godot dependencies.
 */

#include "../evil_engine.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    BLBFile* blb = NULL;
    int level_count, i;
    
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <path/to/GAME.BLB>\n", argv[0]);
        return 1;
    }
    
    /* Open BLB file */
    printf("Opening BLB: %s\n", argv[1]);
    if (EvilEngine_OpenBLB(argv[1], &blb) != 0) {
        fprintf(stderr, "Error: Failed to open BLB file\n");
        return 1;
    }
    
    /* Get basic info */
    level_count = EvilEngine_GetLevelCount(blb);
    printf("\nBLB Archive Information:\n");
    printf("========================\n");
    printf("Level count: %d\n\n", level_count);
    
    /* List all levels */
    printf("Levels:\n");
    printf("-------\n");
    for (i = 0; i < level_count; i++) {
        const char* name = EvilEngine_GetLevelName(blb, i);
        const char* id = EvilEngine_GetLevelID(blb, i);
        
        if (name && id) {
            printf("%2d. [%s] %s\n", i, id, name);
        }
    }
    
    /* Load and display first level details */
    if (level_count > 0) {
        LevelContext* level = NULL;
        const TileHeader* header;
        int layer_count, entity_count, tile_count;
        
        printf("\nLoading level 0 (stage 0) for details...\n");
        if (EvilEngine_LoadLevel(blb, 0, 0, &level) == 0) {
            header = EvilEngine_GetTileHeader(level);
            layer_count = EvilEngine_GetLayerCount(level);
            tile_count = EvilEngine_GetTotalTiles(level);
            
            if (header) {
                printf("\nLevel Details:\n");
                printf("--------------\n");
                printf("Dimensions: %d x %d tiles (%d x %d pixels)\n",
                       header->level_width, header->level_height,
                       header->level_width * 16, header->level_height * 16);
                printf("Spawn: (%d, %d)\n", 
                       header->spawn_x, header->spawn_y);
                printf("Background: RGB(%d, %d, %d)\n",
                       header->bg_r, header->bg_g, header->bg_b);
                printf("Tiles: %d total (%d 16x16, %d 8x8)\n",
                       tile_count, header->count_16x16, header->count_8x8);
                printf("Layers: %d\n", layer_count);
                
                /* Get entity count */
                EvilEngine_GetEntities(level, &entity_count);
                printf("Entities: %d\n", entity_count);
                
                /* Display layer info */
                printf("\nLayer Details:\n");
                for (i = 0; i < layer_count; i++) {
                    const LayerEntry* layer_entry = EvilEngine_GetLayer(level, i);
                    if (layer_entry) {
                        float scroll_x = layer_entry->scroll_x / 65536.0f;
                        float scroll_y = layer_entry->scroll_y / 65536.0f;
                        printf("  Layer %d: %dx%d tiles, scroll=(%.2f, %.2f), type=%d\n",
                               i, layer_entry->width, layer_entry->height,
                               scroll_x, scroll_y, layer_entry->layer_type);
                    }
                }
            }
            
            EvilEngine_UnloadLevel(level);
        } else {
            fprintf(stderr, "Warning: Could not load level 0 for details\n");
        }
    }
    
    /* Cleanup */
    EvilEngine_CloseBLB(blb);
    
    printf("\nDone!\n");
    return 0;
}

