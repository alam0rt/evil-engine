#include "game.h"

void game_init(GameState *state) {
    state->player_x = 0;
    state->player_y = 0;
    state->player_health = 3;
    state->score = 0;
    state->current_level = 0;
    state->current_stage = 0;
}

void game_update(GameState *state, float delta) {
    /* Game logic goes here */
    (void)state;
    (void)delta;
}

void game_input(GameState *state, int32_t dx, int32_t dy, uint8_t buttons) {
    state->player_x += dx;
    state->player_y += dy;
    (void)buttons;
}
