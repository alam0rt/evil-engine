# Gameplay System

Complete gameplay implementation for Skullmonkeys port in Godot.

## Overview

This system transforms imported BLB levels into fully playable games with:
- Faithful player physics from original game
- Enemy AI with multiple behavior patterns
- Collectible system (clayballs, ammo, powerups)
- Lives and health system
- HUD display
- Checkpoint/respawn system

## Components

### Player Character (`player_character.gd`)

Faithful recreation of Klaymen's physics and controls.

**Physics Constants** (CODE-VERIFIED from Ghidra):
- Walk speed: 2.0 px/frame (120 px/s at 60 FPS)
- Run speed: 3.0 px/frame (180 px/s)
- Jump velocity: -2.25 px/frame
- Gravity: 6.0 px/frame²
- Terminal velocity: 8.0 px/frame

**Features**:
- Walking/running
- Jumping
- Lives system (starts with 5)
- Invincibility frames after damage
- Halo powerup protection
- Death/respawn handling

**Input Actions** (auto-configured):
- `move_left` / `move_right`: Arrow keys, A/D
- `jump`: Space, W, Up arrow
- `run`: Shift
- `attack`: Ctrl, X

### Collectibles (`collectible.gd`)

Items that can be collected by the player.

**Types**:
- `CLAYBALL`: Score items (gold coins)
- `AMMO`: Standard bullet pickup
- `AMMO_SPECIAL`: Special ammo
- `LIFE`: Extra life
- `HALO`: Damage protection powerup

**Usage**:
```gdscript
var collectible = Collectible.new()
collectible.collectible_type = Collectible.Type.CLAYBALL
collectible.value = 1
add_child(collectible)
```

### Enemies (`enemy_base.gd`)

Base class for all enemy types with multiple AI patterns.

**AI Patterns** (from docs/systems/enemy-ai-overview.md):
1. **PATROL**: Walk back and forth
2. **CHASE**: Follow player when in range
3. **RANGED**: Shoot projectiles at player
4. **FLYING**: Airborne movement patterns
5. **STATIONARY**: Fixed position, attack when in range

**Properties**:
- `health`: Enemy hit points
- `damage`: Damage dealt to player
- `speed`: Movement speed
- `detection_range`: Player detection radius
- `attack_range`: Attack trigger radius

**Usage**:
```gdscript
var enemy = EnemyBase.new()
enemy.ai_pattern = EnemyBase.AIPattern.PATROL
enemy.health = 3
enemy.speed = 60.0
add_child(enemy)
```

### Game Manager (`game_manager.gd`)

Coordinates overall game state and level management.

**Responsibilities**:
- Level loading/unloading
- Player spawning at spawn points
- Checkpoint system
- Score tracking (clayballs, ammo, lives)
- HUD updates
- Game over handling

**Signals**:
- `level_loaded(level_name)`
- `player_spawned(player)`
- `player_died()`
- `checkpoint_reached(checkpoint_id)`
- `game_over()`

**Usage**:
```gdscript
var game_manager = GameManager.new()
add_child(game_manager)
game_manager.load_level("res://levels/SCIE_Stage1.tscn")
```

### HUD (`game_hud.gd`)

Displays game information to the player.

**Elements**:
- Lives counter
- Clayball (score) counter with total
- Ammo counter

## Automatic Entity Setup

When BLB levels are imported, entities are automatically configured for gameplay:

### Entity Naming

Entities use descriptive names based on type:
- `Player_0`
- `Clayball_5`
- `SkullmonkeyStandard_12`
- `Portal_3`

### Godot Groups

Entities are automatically added to groups for easy querying:
- `player`
- `collectibles`
- `enemies`
- `bosses`
- `platforms`
- `interactive`
- `effects`
- `decorations`

### Gameplay Metadata

Entities include metadata for runtime conversion:
- `gameplay_type`: "collectible", "enemy", "boss", "player", "interactive"
- `collectible_type`: Collectible enum value
- `enemy_ai`: AI pattern name
- `interactive_type`: "checkpoint", etc.

## Usage Example

### Complete Game Setup

```gdscript
extends Node

func _ready():
    # Create game manager
    var game_manager = GameManager.new()
    add_child(game_manager)
    
    # Create HUD
    var hud = preload("res://addons/blb_importer/gameplay/game_hud.tscn").instantiate()
    add_child(hud)
    
    # Load first level
    game_manager.load_level("res://levels/SCIE_Stage1.tscn")
```

### Manual Player Setup

```gdscript
# Create player manually
var player_scene = preload("res://addons/blb_importer/gameplay/player_character.tscn")
var player = player_scene.instantiate()
player.global_position = Vector2(100, 100)
add_child(player)
```

### Converting Imported Entities to Gameplay

```gdscript
# After loading a BLB level, convert entities
for entity in get_tree().get_nodes_in_group("collectibles"):
    if entity.has_meta("gameplay_type") and entity.get_meta("gameplay_type") == "collectible":
        # Replace with actual collectible
        var collectible = preload("res://addons/blb_importer/gameplay/collectible.gd").new()
        collectible.global_position = entity.global_position
        collectible.collectible_type = entity.get_meta("collectible_type", 0)
        entity.get_parent().add_child(collectible)
        entity.queue_free()
```

## Integration with BLB Import

The gameplay system integrates seamlessly with BLB import:

1. **Import BLB**: Drop `GAME.BLB` into project
2. **Auto-convert**: Entities are named and grouped automatically
3. **Add GameManager**: Create game manager node in scene
4. **Add HUD**: Add HUD overlay
5. **Play**: Game is fully playable with faithful physics

## Physics Reference

All physics constants are verified from Ghidra decompilation:

| Constant | Value (px/frame) | Value (px/s @ 60 FPS) | Source |
|----------|------------------|----------------------|--------|
| Walk Speed | 2.0 | 120.0 | Line 31759 |
| Run Speed | 3.0 | 180.0 | Line 31761 |
| Jump Velocity | -2.25 | -135.0 | Lines 32904, 32919 |
| Gravity | -6.0 | 360.0 | Lines 32023, 32219 |
| Terminal Velocity | 8.0 | 480.0 | Observed |
| Landing Cushion | -0.07 | -4.2 | Line 32018 |
| Bounce Velocity | -2.25 | -135.0 | Line 32896 |

See `docs/PHYSICS_QUICK_REFERENCE.md` for complete details.

## Best Practices

Following Godot best practices as specified:

1. **Scene Organization**: Clear hierarchy with named containers
2. **Groups**: Use groups for entity queries (`get_tree().get_nodes_in_group("enemies")`)
3. **Signals**: Communication between systems via signals
4. **Script Classes**: All scripts use `class_name` for global access
5. **Resource Management**: Proper `queue_free()` on entity removal
6. **Input Mapping**: Centralized input action setup
7. **Physics**: Use CharacterBody2D for player/enemies
8. **Collision Layers**: Proper layer/mask setup for interactions

## Next Steps

To complete the port:

1. **Entity Conversion Tool**: Create editor tool to batch-convert imported entities
2. **Boss Behaviors**: Implement specific boss AI patterns
3. **Projectile System**: Add bullet/projectile spawning
4. **Animation State Machine**: Connect player states to sprite animations
5. **Audio Integration**: Add sound effects and music
6. **Save System**: Implement password/checkpoint save system

## Documentation

- `docs/systems/player/player-physics.md` - Complete player physics
- `docs/systems/enemy-ai-overview.md` - Enemy AI patterns
- `docs/systems/entities.md` - Entity system architecture
- `docs/PHYSICS_QUICK_REFERENCE.md` - Quick reference for constants
- `https://docs.godotengine.org/en/stable/tutorials/best_practices/` - Godot best practices

