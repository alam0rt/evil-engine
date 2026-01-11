/**
 * evil_engine.h - Public API for GDExtension
 * 
 * This header defines the C API that the GDExtension wrapper uses.
 * These functions are thin wrappers around the authentic C99 code.
 */

#ifndef EVIL_ENGINE_H
#define EVIL_ENGINE_H

#include "psx/types.h"

/* Opaque handle to engine context */
typedef struct EvilEngineContext EvilEngineContext;

/* Create/destroy engine context */
EvilEngineContext* EvilEngine_Create(void);
void EvilEngine_Destroy(EvilEngineContext* ctx);

/* Load BLB file */
int EvilEngine_LoadBLB(EvilEngineContext* ctx, const char* path);

/* Get level info */
int EvilEngine_GetLevelCount(EvilEngineContext* ctx);
const char* EvilEngine_GetLevelName(EvilEngineContext* ctx, int index);

/* Load a level and stage */
int EvilEngine_LoadLevel(EvilEngineContext* ctx, int level_index, int stage_index);

/* Get loaded level info */
int EvilEngine_GetLevelWidth(EvilEngineContext* ctx);
int EvilEngine_GetLevelHeight(EvilEngineContext* ctx);
int EvilEngine_GetLayerCount(EvilEngineContext* ctx);
int EvilEngine_GetEntityCount(EvilEngineContext* ctx);
int EvilEngine_GetTotalTiles(EvilEngineContext* ctx);

/* Get background color */
void EvilEngine_GetBackgroundColor(EvilEngineContext* ctx, u8* r, u8* g, u8* b);

/* Get spawn position in pixels */
void EvilEngine_GetSpawnPosition(EvilEngineContext* ctx, int* x, int* y);

/* Get layer dimensions in pixels */
void EvilEngine_GetLayerDimensions(EvilEngineContext* ctx, int layer, int* width, int* height);

/* Render a single tile to RGBA buffer (16*16*4 = 1024 bytes max) */
int EvilEngine_RenderTile(EvilEngineContext* ctx, int tile_index, 
                          u8* out_rgba, int* out_width, int* out_height);

/* Render a layer to RGBA buffer */
int EvilEngine_RenderLayer(EvilEngineContext* ctx, int layer_index,
                           u8* out_rgba, int buf_width, int buf_height);

/* Render full level (all layers composited) to RGBA buffer */
int EvilEngine_RenderLevel(EvilEngineContext* ctx,
                           u8* out_rgba, int buf_width, int buf_height);

#endif /* EVIL_ENGINE_H */
