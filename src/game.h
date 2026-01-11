#ifndef EVIL_ENGINE_GAME_H
#define EVIL_ENGINE_GAME_H

/*
 * Portable game logic - no Godot dependencies
 * This code can be reused in other projects (tests, tools, other engines)
 */

#include <stdint.h>
#include <stddef.h>

/* Game state */
typedef struct {
    int32_t player_x;
    int32_t player_y;
    int32_t player_health;
    uint32_t score;
    uint8_t current_level;
    uint8_t current_stage;
} GameState;

/* Initialize game state */
void game_init(GameState *state);

/* Update game logic (called each frame) */
void game_update(GameState *state, float delta);

/* Process player input */
void game_input(GameState *state, int32_t dx, int32_t dy, uint8_t buttons);

#endif /* EVIL_ENGINE_GAME_H */
