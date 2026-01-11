#ifndef EVIL_ENGINE_GAME_H
#define EVIL_ENGINE_GAME_H

/**
 * game.h - Core Game Loop
 * 
 * Based on main() at 0x800828b0 in Skullmonkeys PAL.
 * 
 * Game Loop Order (from Ghidra decompilation):
 * 1. TickCDStreamBuffer() - Stream CD data (we skip - no CD)
 * 2. PadRead(1) - Read controller ports
 * 3. UpdateInputState(P1, P2) - Process button presses/releases
 * 4. [Mode Callback] - Execute current game mode handler
 * 5. EntityTickLoop() - Update all active entities
 * 6. WaitForVBlankIfNeeded() - Conditional VSync
 * 7. RenderEntities() - Draw entity render pass
 * 8. DrawSync(0) - Wait for GPU
 * 9. [Layer Render Callback] - Render tile layers
 * 10. DrawSync(0) - Wait again
 * 11. VSync frame timing
 * 12. FlushDebugFontAndEndFrame()
 */

#include "../psx/types.h"
#include "../blb/blb.h"
#include "../level/level.h"

/* -----------------------------------------------------------------------------
 * Input State
 * Based on UpdateInputState at 0x800259d4
 * -------------------------------------------------------------------------- */

#define PAD_UP       0x0010
#define PAD_DOWN     0x0040
#define PAD_LEFT     0x0080
#define PAD_RIGHT    0x0020
#define PAD_CROSS    0x4000
#define PAD_CIRCLE   0x2000
#define PAD_SQUARE   0x8000
#define PAD_TRIANGLE 0x1000
#define PAD_L1       0x0004
#define PAD_L2       0x0001
#define PAD_R1       0x0008
#define PAD_R2       0x0002
#define PAD_START    0x0800
#define PAD_SELECT   0x0100

typedef struct {
    u16 held;           /* Currently held buttons */
    u16 pressed;        /* Just pressed this frame (edge detect) */
    u16 released;       /* Just released this frame */
    u16 prev;           /* Previous frame held state */
} InputState;

/* -----------------------------------------------------------------------------
 * Entity System (simplified from 0x44C byte structure)
 * Based on EntityTickLoop at 0x80020e1c
 * -------------------------------------------------------------------------- */

#define ENTITY_MAX_ACTIVE   128

struct Entity;
struct GameState;

typedef void (*EntityCallback)(struct Entity* entity, struct GameState* state);

typedef struct Entity {
    struct Entity* next;        /* Linked list (offset 0x00 in original) */
    struct Entity* prev;
    
    u32 state;                  /* State machine (offset 0x00) */
    EntityCallback callback;    /* Update callback (offset 0x04) */
    
    s32 x, y;                   /* Position (offset 0x68-0x6B) */
    s32 vel_x, vel_y;           /* Velocity */
    
    u16 entity_type;            /* Type ID */
    u16 variant;                /* Subtype/variant */
    u16 layer;                  /* Render layer */
    
    u8 visibility;              /* Visible flag (offset 0xF6) */
    u8 flags;                   /* Entity flags (offset 0xF7) */
    u8 active;                  /* In active list */
    u8 marked_for_removal;      /* Remove next frame */
    
    u32 sprite_id;              /* Sprite lookup ID */
    u16 frame;                  /* Current animation frame */
    u16 anim_timer;             /* Animation timer */
    
    const EntityDef* def;       /* Back-reference to BLB definition */
} Entity;

/* -----------------------------------------------------------------------------
 * Game Mode (state machine)
 * Based on mode dispatch in main() - mode byte at header[0xF36]
 * -------------------------------------------------------------------------- */

typedef enum {
    GAME_MODE_NONE      = 0,
    GAME_MODE_MOVIE     = 1,    /* FMV playback */
    GAME_MODE_CREDITS   = 2,    /* Credits sequence */
    GAME_MODE_LEVEL     = 3,    /* Level gameplay */
    GAME_MODE_SECTOR_4  = 4,    /* Sector-based op */
    GAME_MODE_SECTOR_5  = 5,    /* Sector-based op */
    GAME_MODE_SPECIAL   = 6,    /* Special/transition */
} GameMode;

typedef void (*ModeCallback)(struct GameState* state);

/* -----------------------------------------------------------------------------
 * GameState - Main game state structure
 * Based on g_GameStateBase at 0x8009DC40
 * LevelDataContext at GameState + 0x84 (0x8009DCC4)
 * -------------------------------------------------------------------------- */

typedef struct GameState {
    /* Mode dispatch (offset 0x00-0x08 in original) */
    GameMode mode;
    ModeCallback mode_callback;
    
    /* Input (original uses g_pPlayer1Input/g_pPlayer2Input) */
    InputState input_p1;
    InputState input_p2;
    InputState* current_input;
    
    /* Entity lists (offset 0x1C, 0x20 in original) */
    Entity* active_entity_head;     /* +0x1C: Active entities */
    Entity* render_entity_head;     /* +0x20: Render order list */
    Entity entity_pool[ENTITY_MAX_ACTIVE];
    u32 entity_pool_next;
    
    /* Level data (offset 0x84 = LevelDataContext) */
    LevelContext level;
    
    /* BLB archive */
    BLBFile blb;
    int blb_loaded;
    
    /* Current level/stage */
    u8 level_index;
    u8 stage_index;
    
    /* Sliding window state machine (offset 0x60 in LevelDataContext) */
    u8 header_offset;
    
    /* Camera position */
    s32 camera_x;
    s32 camera_y;
    
    /* Background color (offset 0x130-0x133 in original) */
    u8 bg_r, bg_g, bg_b;
    u8 bg_dirty;
    
    /* Frame counter */
    u32 frame_count;
    
    /* Game flags (used for VSync timing) */
    u32 game_flags;
    
    /* Debug */
    u8 debug_enabled;
    u8 paused;
} GameState;

/* -----------------------------------------------------------------------------
 * Game Functions
 * -------------------------------------------------------------------------- */

/**
 * Initialize game state.
 * Equivalent to InitGameState at 0x8007cd34.
 */
void Game_Init(GameState* state);

/**
 * Load BLB archive.
 */
int Game_LoadBLB(GameState* state, const char* path);

/**
 * Load a level.
 * Equivalent to InitializeAndLoadLevel at 0x8007D1D0.
 */
int Game_LoadLevel(GameState* state, u8 level_index, u8 stage_index);

/**
 * Process input.
 * Equivalent to UpdateInputState at 0x800259d4.
 */
void Game_UpdateInput(InputState* input, u16 buttons);

/**
 * Main game tick - call once per frame.
 * This is the main game loop body from main().
 */
void Game_Tick(GameState* state, u16 p1_buttons, u16 p2_buttons);

/**
 * Entity tick loop.
 * Equivalent to EntityTickLoop at 0x80020e1c.
 */
void Game_EntityTickLoop(GameState* state);

/**
 * Render entities.
 * Equivalent to RenderEntities at 0x80020e80.
 */
void Game_RenderEntities(GameState* state);

/**
 * Spawn an entity from definition.
 */
Entity* Game_SpawnEntity(GameState* state, const EntityDef* def);

/**
 * Spawn player at spawn point.
 */
Entity* Game_SpawnPlayer(GameState* state);

/**
 * Remove entity from active list.
 */
void Game_RemoveEntity(GameState* state, Entity* entity);

/**
 * Get player entity.
 */
Entity* Game_GetPlayer(GameState* state);

/**
 * Cleanup.
 */
void Game_Shutdown(GameState* state);

#endif /* EVIL_ENGINE_GAME_H */
