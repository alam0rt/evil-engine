#include <gdextension_interface.h>
#include <stdlib.h>
#include "game.h"

/*
 * EvilEngineNode - Godot node wrapping portable game logic
 * 
 * This demonstrates how to expose C game code to Godot.
 * The actual game logic lives in src/game.c and has no Godot deps.
 */

typedef struct {
    GameState game_state;
} EvilEngineNode;

/* Called when node is created */
static void *engine_node_create(void *p_userdata) {
    (void)p_userdata;
    EvilEngineNode *node = (EvilEngineNode *)malloc(sizeof(EvilEngineNode));
    if (node) {
        game_init(&node->game_state);
    }
    return node;
}

/* Called when node is destroyed */
static void engine_node_free(void *p_userdata, GDExtensionClassInstancePtr p_instance) {
    (void)p_userdata;
    free(p_instance);
}

/* Register the class with Godot */
void engine_node_register(GDExtensionClassLibraryPtr p_library) {
    /* TODO: Full class registration requires more GDExtension boilerplate */
    /* For now this is a placeholder showing the pattern */
    (void)p_library;
    (void)engine_node_create;
    (void)engine_node_free;
}
