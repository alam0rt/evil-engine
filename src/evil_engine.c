/**
 * evil_engine.c - Public API Implementation
 * 
 * Wraps the authentic C99 engine code for use by GDExtension.
 */

#include "evil_engine.h"
#include "blb/blb.h"
#include "level/level.h"
#include "render/render.h"
#include <stdlib.h>
#include <string.h>

struct EvilEngineContext {
    BLBFile blb;
    LevelContext level;
    int blb_loaded;
    int level_loaded;
};

EvilEngineContext* EvilEngine_Create(void) {
    EvilEngineContext* ctx = (EvilEngineContext*)calloc(1, sizeof(EvilEngineContext));
    if (ctx) {
        Level_Init(&ctx->level);
    }
    return ctx;
}

void EvilEngine_Destroy(EvilEngineContext* ctx) {
    if (!ctx) return;
    
    if (ctx->level_loaded) {
        Level_Unload(&ctx->level);
    }
    if (ctx->blb_loaded) {
        BLB_Close(&ctx->blb);
    }
    free(ctx);
}

int EvilEngine_LoadBLB(EvilEngineContext* ctx, const char* path) {
    if (!ctx || !path) return -1;
    
    /* Close existing if any */
    if (ctx->level_loaded) {
        Level_Unload(&ctx->level);
        ctx->level_loaded = 0;
    }
    if (ctx->blb_loaded) {
        BLB_Close(&ctx->blb);
        ctx->blb_loaded = 0;
    }
    
    if (BLB_Open(path, &ctx->blb) != 0) {
        return -1;
    }
    ctx->blb_loaded = 1;
    return 0;
}

int EvilEngine_GetLevelCount(EvilEngineContext* ctx) {
    if (!ctx || !ctx->blb_loaded) return 0;
    return ctx->blb.level_count;
}

const char* EvilEngine_GetLevelName(EvilEngineContext* ctx, int index) {
    if (!ctx || !ctx->blb_loaded) return NULL;
    return BLB_GetLevelName(&ctx->blb, index);
}

int EvilEngine_LoadLevel(EvilEngineContext* ctx, int level_index, int stage_index) {
    if (!ctx || !ctx->blb_loaded) return -1;
    
    if (ctx->level_loaded) {
        Level_Unload(&ctx->level);
        ctx->level_loaded = 0;
    }
    
    Level_Init(&ctx->level);
    if (Level_Load(&ctx->level, &ctx->blb, (u8)level_index, (u8)stage_index) != 0) {
        return -1;
    }
    ctx->level_loaded = 1;
    return 0;
}

int EvilEngine_GetLevelWidth(EvilEngineContext* ctx) {
    if (!ctx || !ctx->level_loaded || !ctx->level.tile_header) return 0;
    return ctx->level.tile_header->level_width * 16;
}

int EvilEngine_GetLevelHeight(EvilEngineContext* ctx) {
    if (!ctx || !ctx->level_loaded || !ctx->level.tile_header) return 0;
    return ctx->level.tile_header->level_height * 16;
}

int EvilEngine_GetLayerCount(EvilEngineContext* ctx) {
    if (!ctx || !ctx->level_loaded) return 0;
    return (int)ctx->level.layer_count;
}

int EvilEngine_GetEntityCount(EvilEngineContext* ctx) {
    if (!ctx || !ctx->level_loaded) return 0;
    return (int)ctx->level.entity_count;
}

int EvilEngine_GetTotalTiles(EvilEngineContext* ctx) {
    if (!ctx || !ctx->level_loaded) return 0;
    return (int)ctx->level.total_tiles;
}

void EvilEngine_GetBackgroundColor(EvilEngineContext* ctx, u8* r, u8* g, u8* b) {
    if (!ctx || !ctx->level_loaded) {
        if (r) *r = 0;
        if (g) *g = 0;
        if (b) *b = 0;
        return;
    }
    Level_GetBackgroundColor(&ctx->level, r, g, b);
}

void EvilEngine_GetSpawnPosition(EvilEngineContext* ctx, int* x, int* y) {
    s32 sx, sy;
    if (!ctx || !ctx->level_loaded) {
        if (x) *x = 0;
        if (y) *y = 0;
        return;
    }
    Level_GetSpawnPosition(&ctx->level, &sx, &sy);
    if (x) *x = (int)sx;
    if (y) *y = (int)sy;
}

void EvilEngine_GetLayerDimensions(EvilEngineContext* ctx, int layer, int* width, int* height) {
    if (!ctx || !ctx->level_loaded) {
        if (width) *width = 0;
        if (height) *height = 0;
        return;
    }
    GetLayerPixelDimensions(&ctx->level, (u32)layer, width, height);
}

int EvilEngine_RenderTile(EvilEngineContext* ctx, int tile_index, 
                          u8* out_rgba, int* out_width, int* out_height) {
    if (!ctx || !ctx->level_loaded) return -1;
    return RenderTileToRGBA(&ctx->level, (u16)tile_index, out_rgba, out_width, out_height);
}

int EvilEngine_RenderLayer(EvilEngineContext* ctx, int layer_index,
                           u8* out_rgba, int buf_width, int buf_height) {
    if (!ctx || !ctx->level_loaded) return -1;
    return RenderLayerToRGBA(&ctx->level, (u32)layer_index, out_rgba, buf_width, buf_height);
}

int EvilEngine_RenderLevel(EvilEngineContext* ctx,
                           u8* out_rgba, int buf_width, int buf_height) {
    u8 bg_r, bg_g, bg_b;
    u32 layer;
    int i;
    
    if (!ctx || !ctx->level_loaded || !out_rgba) return -1;
    
    /* Fill with background color */
    Level_GetBackgroundColor(&ctx->level, &bg_r, &bg_g, &bg_b);
    for (i = 0; i < buf_width * buf_height; i++) {
        out_rgba[i * 4 + 0] = bg_r;
        out_rgba[i * 4 + 1] = bg_g;
        out_rgba[i * 4 + 2] = bg_b;
        out_rgba[i * 4 + 3] = 255;
    }
    
    /* Render layers back to front */
    for (layer = 0; layer < ctx->level.layer_count; layer++) {
        const LayerEntry* le = Level_GetLayer(&ctx->level, layer);
        if (le && le->layer_type != 3) {  /* type 3 = skip */
            RenderLayerToRGBA(&ctx->level, layer, out_rgba, buf_width, buf_height);
        }
    }
    
    return 0;
}
