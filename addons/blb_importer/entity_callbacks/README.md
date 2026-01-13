# Entity Callbacks

PSX-authentic entity callback system for Skullmonkeys (SLES-01090).

## Architecture

Based on Godot best practices ([scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)):

1. **Scenes as classes**: Each entity type is a script extending `BLBEntityBase`
2. **Loose coupling**: Entities emit signals, GameRunner connects and responds
3. **No hard dependencies**: Entities receive game state via method parameters

### PSX Reference

- **Entity Callback Table**: 121 entries at `g_EntityTypeCallbackTable` (0x8009d5f8)
- **EntityTickLoop** (0x80020e1c): Iterates entities and calls callbacks each frame
- **RemapEntityTypesForLevel** (0x8008150c): Converts BLB type → internal type

## Scene Structure

When StageSceneBuilder creates entities, each is a `BLBEntityBase` node:

```
Entity_0_T2 (EntityClayball script)
└── Sprite (AnimatedSprite2D)

Entity_1_T25 (EntityEnemy script)
└── Sprite (AnimatedSprite2D)
```

## Signals (Loose Coupling)

Entities emit signals instead of directly calling GameRunner methods:

```gdscript
# In entity script:
collected.emit(self, 100)  # Score value
player_damaged.emit(self, 1)  # Damage amount
portal_activated.emit(self, destination)
message_triggered.emit(self, message_id)
entity_killed.emit(self)
```

GameRunner connects to these signals when entities are loaded.

## Entity Lifecycle

1. **`_entity_init()`**: Called in `_ready()` when entity spawns
2. **`entity_tick(game_state)`**: Called by GameRunner each frame
3. **Signals**: Emit events for GameRunner to handle

### game_state Dictionary

Passed to `entity_tick()` each frame:

```gdscript
{
    "player_x": float,
    "player_y": float,
    "player_width": float,
    "player_height": float,
    "camera_x": float,
    "camera_y": float,
    "frame_count": int,
    "input_state": Dictionary,
}
```

## Entity Type → Script Mapping

See `entity_callback_registry.gd` for full mapping. Key types:

| Internal Type | Script Class | Description |
|---------------|--------------|-------------|
| 2 | EntityClayball | Collectible coin |
| 8 | EntityItem | Generic pickup |
| 24 | EntityAmmo | Ammo pickup |
| 25, 27 | EntityEnemy | Enemies |
| 28, 48 | EntityPlatform | Moving platforms |
| 42-44, 53-55 | EntityPortal | Warps/portals |
| 45 | EntityMessage | Save/message boxes |
| 50, 51 | EntityBoss | Boss entities |
| 60, 61 | EntityParticle | Particle effects |

## Creating New Entity Types

1. Create script extending `BLBEntityBase`
2. Override `_entity_init()` and `_entity_tick()`
3. Register in `entity_callback_registry.gd`

Example:
```gdscript
@tool
class_name EntityMyType
extends BLBEntityBase

func _entity_init() -> void:
    play_animation("idle")

func _entity_tick(game_state: Dictionary) -> void:
    if not is_on_screen(game_state):
        return
    
    if check_player_collision(game_state):
        collect(100)  # Emits collected signal
```

## Files

- `blb_entity_base.gd` - Base class for all entities
- `entity_callback_registry.gd` - Type → script mapping
- `types/` - Individual entity type scripts

## Reference

- PSX callback table: `btm/docs/reference/entity-types.md`
- Entity system: `btm/docs/systems/entities.md`
- Entity identification: `btm/docs/systems/entity-identification.md`
- Godot best practices: [scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
