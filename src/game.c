/**
 * game.c - Core Game Loop Implementation
 * 
 * Based on main() at 0x800828b0 and supporting functions from Ghidra.
 */

#include "game.h"
#include <string.h>

/* -----------------------------------------------------------------------------
 * Internal Helpers
 * -------------------------------------------------------------------------- */

static void entity_init(Entity* entity) {
    memset(entity, 0, sizeof(Entity));
}

static Entity* entity_alloc(GameState* state) {
    if (state->entity_pool_next >= ENTITY_MAX_ACTIVE) {
        return NULL;
    }
    Entity* e = &state->entity_pool[state->entity_pool_next++];
    entity_init(e);
    e->active = 1;
    return e;
}

static void entity_add_to_list(Entity** head, Entity* entity) {
    entity->next = *head;
    entity->prev = NULL;
    if (*head) {
        (*head)->prev = entity;
    }
    *head = entity;
}

static void entity_remove_from_list(Entity** head, Entity* entity) {
    if (entity->prev) {
        entity->prev->next = entity->next;
    } else {
        *head = entity->next;
    }
    if (entity->next) {
        entity->next->prev = entity->prev;
    }
    entity->next = NULL;
    entity->prev = NULL;
}

/* -----------------------------------------------------------------------------
 * Game Initialization
 * Based on InitGameState at 0x8007cd34
 * -------------------------------------------------------------------------- */

void Game_Init(GameState* state) {
    memset(state, 0, sizeof(GameState));
    
    /* Initialize level context */
    Level_Init(&state->level);
    
    /* Set default background color (from main(): 0x40, 0x20, 0x80) */
    state->bg_r = 0x40;
    state->bg_g = 0x20;
    state->bg_b = 0x80;
    state->bg_dirty = 1;
    
    /* Set default input to P1 */
    state->current_input = &state->input_p1;
    
    /* Start in no mode */
    state->mode = GAME_MODE_NONE;
    state->mode_callback = NULL;
}

int Game_LoadBLB(GameState* state, const char* path) {
    if (state->blb_loaded) {
        BLB_Close(&state->blb);
        state->blb_loaded = 0;
    }
    
    if (BLB_Open(path, &state->blb) == 0) {
        state->blb_loaded = 1;
        return 0;
    }
    return -1;
}

/* -----------------------------------------------------------------------------
 * Level Loading
 * Based on InitializeAndLoadLevel at 0x8007D1D0
 * -------------------------------------------------------------------------- */

int Game_LoadLevel(GameState* state, u8 level_index, u8 stage_index) {
    if (!state->blb_loaded) {
        return -1;
    }
    
    /* Unload previous level */
    Level_Unload(&state->level);
    
    /* Clear entities */
    state->active_entity_head = NULL;
    state->render_entity_head = NULL;
    state->entity_pool_next = 0;
    memset(state->entity_pool, 0, sizeof(state->entity_pool));
    
    /* Load new level */
    if (Level_Load(&state->level, &state->blb, level_index, stage_index) != 0) {
        return -1;
    }
    
    state->level_index = level_index;
    state->stage_index = stage_index;
    state->mode = GAME_MODE_LEVEL;
    
    /* Get background color from level */
    Level_GetBackgroundColor(&state->level, &state->bg_r, &state->bg_g, &state->bg_b);
    state->bg_dirty = 1;
    
    /* Reset camera to spawn position */
    s32 spawn_x, spawn_y;
    Level_GetSpawnPosition(&state->level, &spawn_x, &spawn_y);
    state->camera_x = spawn_x - 160; /* Center on screen (320/2) */
    state->camera_y = spawn_y - 120; /* Center on screen (240/2) */
    
    /* Spawn player */
    Game_SpawnPlayer(state);
    
    return 0;
}

/* -----------------------------------------------------------------------------
 * Input Processing
 * Based on UpdateInputState at 0x800259d4
 * -------------------------------------------------------------------------- */

void Game_UpdateInput(InputState* input, u16 buttons) {
    input->prev = input->held;
    input->held = buttons;
    
    /* Edge detection */
    input->pressed = buttons & ~input->prev;    /* New presses */
    input->released = input->prev & ~buttons;   /* New releases */
}

/* -----------------------------------------------------------------------------
 * Entity Tick Loop
 * Based on EntityTickLoop at 0x80020e1c:
 * 
 * for (entity = state+0x1c; entity != NULL; entity = entity->next) {
 *     callback = entity[1]->callback;  // +0x18 -> +0x14 dispatch
 *     callback(entity[1] + offset);
 * }
 * -------------------------------------------------------------------------- */

void Game_EntityTickLoop(GameState* state) {
    Entity* entity = state->active_entity_head;
    Entity* next;
    
    while (entity != NULL) {
        next = entity->next;
        
        /* Call entity's update callback if set */
        if (entity->callback != NULL && entity->active) {
            entity->callback(entity, state);
        }
        
        /* Remove if marked */
        if (entity->marked_for_removal) {
            Game_RemoveEntity(state, entity);
        }
        
        entity = next;
    }
}

/* -----------------------------------------------------------------------------
 * Entity Rendering
 * Based on RenderEntities at 0x80020e80:
 * 
 * if (bg_dirty) { update background color }
 * for (entity = state+0x1c; entity != NULL; entity = entity->next) { }
 * for (entity = state+0x20; entity != NULL; entity = entity->next) {
 *     render_callback(entity);
 * }
 * -------------------------------------------------------------------------- */

void Game_RenderEntities(GameState* state) {
    /* Background color update (offsets 0x130-0x133 in original) */
    if (state->bg_dirty) {
        /* In Godot, we'll set this via the node */
        state->bg_dirty = 0;
    }
    
    /* First pass: iterate active entities (empty in original - just traverses) */
    Entity* entity = state->active_entity_head;
    while (entity != NULL) {
        /* Original does nothing here - just iterates */
        entity = entity->next;
    }
    
    /* Second pass: render entities from render list */
    entity = state->render_entity_head;
    while (entity != NULL) {
        /* In original: calls render callback at entity[1]+0xC */
        /* For our reimplementation, visibility data is collected by Godot */
        entity = entity->next;
    }
}

/* -----------------------------------------------------------------------------
 * Main Game Tick
 * Based on main() game loop at 0x800828b0
 * -------------------------------------------------------------------------- */

void Game_Tick(GameState* state, u16 p1_buttons, u16 p2_buttons) {
    if (state->paused) {
        return;
    }
    
    /* 1. CD streaming (skip - no CD in reimplementation) */
    
    /* 2-3. Input processing */
    Game_UpdateInput(&state->input_p1, p1_buttons);
    Game_UpdateInput(&state->input_p2, p2_buttons);
    
    /* 4. Mode callback dispatch */
    if (state->mode != GAME_MODE_NONE && state->mode_callback != NULL) {
        state->mode_callback(state);
    }
    
    /* 5. Entity tick loop */
    Game_EntityTickLoop(state);
    
    /* 6. VSync wait (handled by Godot) */
    
    /* 7. Render entities */
    Game_RenderEntities(state);
    
    /* 8-10. DrawSync / Layer render (handled by Godot) */
    
    /* 11. VSync frame timing (handled by Godot) */
    
    /* 12. Debug (optional) */
    
    state->frame_count++;
}

/* -----------------------------------------------------------------------------
 * Entity Management
 * -------------------------------------------------------------------------- */

Entity* Game_SpawnEntity(GameState* state, const EntityDef* def) {
    Entity* entity = entity_alloc(state);
    if (!entity) {
        return NULL;
    }
    
    entity->def = def;
    entity->entity_type = def->entity_type;
    entity->variant = def->variant;
    entity->layer = def->layer;
    entity->x = (s32)def->x_center << 16; /* Fixed point 16.16 */
    entity->y = (s32)def->y_center << 16;
    entity->visibility = 1;
    
    /* Add to active list */
    entity_add_to_list(&state->active_entity_head, entity);
    
    /* Also add to render list */
    entity_add_to_list(&state->render_entity_head, entity);
    
    return entity;
}

/* Default player update callback */
static void player_callback(Entity* entity, GameState* state) {
    InputState* input = state->current_input;
    
    /* Simple movement based on input */
    s32 speed = 0x20000; /* ~2 pixels per frame in 16.16 fixed point */
    
    if (input->held & PAD_LEFT) {
        entity->vel_x = -speed;
    } else if (input->held & PAD_RIGHT) {
        entity->vel_x = speed;
    } else {
        entity->vel_x = 0;
    }
    
    if (input->held & PAD_UP) {
        entity->vel_y = -speed;
    } else if (input->held & PAD_DOWN) {
        entity->vel_y = speed;
    } else {
        entity->vel_y = 0;
    }
    
    /* Apply velocity */
    entity->x += entity->vel_x;
    entity->y += entity->vel_y;
    
    /* Update camera to follow player */
    state->camera_x = (entity->x >> 16) - 160;
    state->camera_y = (entity->y >> 16) - 120;
}

Entity* Game_SpawnPlayer(GameState* state) {
    Entity* player = entity_alloc(state);
    if (!player) {
        return NULL;
    }
    
    /* Get spawn position from level */
    s32 spawn_x, spawn_y;
    Level_GetSpawnPosition(&state->level, &spawn_x, &spawn_y);
    
    player->x = spawn_x << 16;  /* Fixed point 16.16 */
    player->y = spawn_y << 16;
    player->entity_type = 0;    /* Player is type 0 */
    player->visibility = 1;
    player->callback = player_callback;
    
    /* Add to active list */
    entity_add_to_list(&state->active_entity_head, player);
    entity_add_to_list(&state->render_entity_head, player);
    
    return player;
}

void Game_RemoveEntity(GameState* state, Entity* entity) {
    entity_remove_from_list(&state->active_entity_head, entity);
    entity_remove_from_list(&state->render_entity_head, entity);
    entity->active = 0;
}

Entity* Game_GetPlayer(GameState* state) {
    /* Player is always first spawned entity */
    Entity* entity = state->active_entity_head;
    while (entity != NULL) {
        if (entity->entity_type == 0) {
            return entity;
        }
        entity = entity->next;
    }
    return NULL;
}

void Game_Shutdown(GameState* state) {
    Level_Unload(&state->level);
    if (state->blb_loaded) {
        BLB_Close(&state->blb);
        state->blb_loaded = 0;
    }
}
