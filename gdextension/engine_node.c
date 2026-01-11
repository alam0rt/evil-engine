#include <gdextension_interface.h>
#include <stdlib.h>
#include <string.h>
#include "game.h"

/*
 * EvilEngineNode - Godot node wrapping portable game logic
 * 
 * Loads BLB archive and exposes level data to Godot for rendering.
 * The actual game logic lives in src/ and has no Godot dependencies.
 * 
 * The game loop mirrors the original main() at 0x800828b0:
 * - Game_Tick() is called each frame from Godot's _process()
 * - Input is passed from Godot's input system
 * - Rendering data is read by Godot for display
 */

typedef struct {
    GameState game;
} EvilEngineNode;

/* Called when node is created */
static void *engine_node_create(void *p_userdata) {
    (void)p_userdata;
    EvilEngineNode *node = (EvilEngineNode *)malloc(sizeof(EvilEngineNode));
    if (node) {
        Game_Init(&node->game);
    }
    return node;
}

/* Called when node is destroyed */
static void engine_node_free(void *p_userdata, GDExtensionClassInstancePtr p_instance) {
    (void)p_userdata;
    EvilEngineNode *node = (EvilEngineNode *)p_instance;
    if (node) {
        Game_Shutdown(&node->game);
        free(node);
    }
}

/* Load BLB archive file */
static int engine_node_load_blb(EvilEngineNode *node, const char *path) {
    return Game_LoadBLB(&node->game, path) == 0 ? 1 : 0;
}

/* Load a specific level and stage */
static int engine_node_load_level(EvilEngineNode *node, u8 level_index, u8 stage) {
    return Game_LoadLevel(&node->game, level_index, stage) == 0 ? 1 : 0;
}

/* Process one frame (called from Godot _process) */
static void engine_node_tick(EvilEngineNode *node, u16 p1_buttons, u16 p2_buttons) {
    Game_Tick(&node->game, p1_buttons, p2_buttons);
}

/* Get current camera position */
static void engine_node_get_camera(EvilEngineNode *node, s32 *x, s32 *y) {
    if (x) *x = node->game.camera_x;
    if (y) *y = node->game.camera_y;
}

/* Get background color */
static void engine_node_get_bg_color(EvilEngineNode *node, u8 *r, u8 *g, u8 *b) {
    if (r) *r = node->game.bg_r;
    if (g) *g = node->game.bg_g;
    if (b) *b = node->game.bg_b;
}

/* Get player position (in pixels) */
static void engine_node_get_player_pos(EvilEngineNode *node, s32 *x, s32 *y) {
    Entity *player = Game_GetPlayer(&node->game);
    if (player) {
        if (x) *x = player->x >> 16;  /* Convert from 16.16 fixed point */
        if (y) *y = player->y >> 16;
    } else {
        if (x) *x = 0;
        if (y) *y = 0;
    }
}

/* Get level info for debugging */
static const char* engine_node_get_level_name(EvilEngineNode *node) {
    if (!node->game.blb_loaded) {
        return NULL;
    }
    return BLB_GetLevelName(&node->game.blb, node->game.level_index);
}

/* Get level count */
static u8 engine_node_get_level_count(EvilEngineNode *node) {
    if (!node->game.blb_loaded) {
        return 0;
    }
    return BLB_GetLevelCount(&node->game.blb);
}

/* Access level context for rendering */
static const LevelContext* engine_node_get_level(EvilEngineNode *node) {
    return &node->game.level;
}

/* Register the class with Godot */
void engine_node_register(GDExtensionClassLibraryPtr p_library) {
    /* TODO: Full class registration requires more GDExtension boilerplate */
    /* For now this is a placeholder showing the pattern */
    (void)p_library;
    (void)engine_node_create;
    (void)engine_node_free;
    (void)engine_node_load_blb;
    (void)engine_node_load_level;
    (void)engine_node_tick;
    (void)engine_node_get_camera;
    (void)engine_node_get_bg_color;
    (void)engine_node_get_player_pos;
    (void)engine_node_get_level_name;
    (void)engine_node_get_level_count;
    (void)engine_node_get_level;
}
