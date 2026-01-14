# Projectile & Weapon System

**Status**: ✅ FULLY DOCUMENTED from decompiled source  
**Source**: SLES_010.90.c lines 35299-35322  
**Function**: `SpawnProjectileEntity` @ 0x80070414

## Overview

The player can shoot projectiles using a trigonometry-based trajectory system. Projectiles are spawned as entities with calculated velocity vectors.

## Projectile Spawning

### SpawnProjectileEntity Function

**Signature**:
```c
void SpawnProjectileEntity(int player_entity, uint angle, int speed)
```

**Parameters**:
- `player_entity` - Pointer to player entity (source)
- `angle` - Launch angle (0-4095, where 0 = right, 0xC00 = up)
- `speed` - Launch speed multiplier

**Algorithm**:
```c
// 1. Calculate angle (inverted from input)
int adjusted_angle = 0xC00 - (angle & 0xFFFF);  // 3072 - angle

// 2. Calculate velocity components using PSX fixed-point trig
int vel_y = csin(adjusted_angle) * speed >> 0xC;  // >> 12 bits
int vel_x = ccos(adjusted_angle) * speed >> 0xC;

// 3. Allocate projectile entity (0x114 = 276 bytes)
void* entity = AllocateFromHeap(blbHeaderBufferBase, 0x114, 1, 0);

// 4. Initialize with sprite and velocity
entity = InitEntity_168254b5(
    entity,
    player_entity[0x60],          // Source entity ID
    player_entity[0x68] + vel_x,  // Spawn X (player X + offset)
    player_entity[0x6a] - vel_y,  // Spawn Y (player Y - offset, inverted)
    vel_x << 10,                  // X velocity (scaled by 1024)
    -vel_y << 10                  // Y velocity (scaled & inverted)
);

// 5. Add to render list
AddEntityToSortedRenderList(g_GameStatePtr, entity);
```

## Constants

| Constant | Hex Value | Decimal | Purpose |
|----------|-----------|---------|---------|
| **Angle Base** | `0xC00` | 3,072 | Base angle for upward direction |
| **Trig Shift** | `>> 0xC` | Right shift 12 | Fixed-point trig result scaling |
| **Velocity Scale** | `<< 10` | Left shift 10 | Final velocity amplification (×1024) |
| **Entity Size** | `0x114` | 276 bytes | Projectile entity allocation size |
| **Projectile Sprite** | `0x168254b5` | - | Sprite hash for projectile graphics |

## Angle System

**Angle Format**: 12-bit value (0-4095)

| Angle | Hex | Direction |
|-------|-----|-----------|
| 0 | `0x000` | Right (0°) |
| 1024 | `0x400` | Down (90°) |
| 2048 | `0x800` | Left (180°) |
| 3072 | `0xC00` | Up (270°) |

**Angle Inversion**: `adjusted = 0xC00 - input_angle`
- This converts the input angle to the PSX coordinate system

## Velocity Calculation

**PSX Trig Functions**: `csin()` and `ccos()` return 12-bit fixed-point values

**Example Calculation** (shooting upward at 0xC00 with speed=16):
```c
adjusted_angle = 0xC00 - 0xC00 = 0x000;  // Points right after adjustment
vel_y = csin(0x000) * 16 >> 12 = 0 * 16 >> 12 = 0;
vel_x = ccos(0x000) * 16 >> 12 = 4096 * 16 >> 12 = 16;

// Final velocity (scaled):
velocity_x = 16 << 10 = 16,384 (0.25 px/frame in 16.16 fixed)
velocity_y = 0 << 10 = 0
```

**Typical Speed Values**: 10-30 (produces velocities of 0.15-0.45 px/frame after scaling)

## Ammo System

### Ammo Storage

**Location**: `g_pPlayerState` global array

| Offset | Field | Description |
|--------|-------|-------------|
| `[0x1A]` | `max_green_bullets` | Maximum green bullet count (default: 3) |

**Initialization** (from line 42542):
```c
// @ 0x80082380: Max Green Bullets initialization
g_pPlayerState[0x1A] = 3;
```

### Ammo Types

Based on entity types in Asset 501:

| Entity Type | Name | Description |
|-------------|------|-------------|
| 3 | Standard Ammo | Regular bullet pickup |
| 24 | Special Ammo | Enhanced ammunition |

## Projectile Entity Structure

**Size**: 0x114 (276 bytes)  
**Sprite ID**: `0x168254b5`

**Key Offsets** (inherited from base entity):
| Offset | Field | Description |
|--------|-------|-------------|
| `+0x60` | `source_id` | Entity that spawned this projectile |
| `+0x68` | `x_position` | Current X position |
| `+0x6A` | `y_position` | Current Y position |
| `+0x104` | `velocity_x` | X velocity (16.16 fixed-point) |
| `+0x108` | `velocity_y` | Y velocity (16.16 fixed-point) |

## Projectile Collision

**Damage Calculation** (from entity collision @ line 33063):
```c
// Read damage value from player entity
damage = player_entity[0x44];

// Half damage if flag set
if (player_entity[0x16] == 0x8000) {
    damage = damage >> 1;  // 50% damage
}
```

**Damage Storage**:
- `entity[0x44]` - Base damage value
- `entity[0x16]` - Damage modifier flag (`0x8000` = half damage)

## Explosion/Debris System

**Related Function**: Spawns 8 projectiles in a circle pattern (line 35090)

```c
// Spawns explosion particles at different angles
for (int i = 0; i < 8; i++) {
    angle = i * (4096 / 8);  // Divide circle into 8 segments
    SpawnProjectileEntity(entity, angle, speed);
}
```

**Debris Sprite IDs**:
- `0xBE68D0C6` - Debris particle type 1
- `0xB868D0C6` - Debris particle type 2
- `0xB468D0C6` - Debris particle type 3

## Sound Effects

| Sound ID | Hex Value | Context |
|----------|-----------|---------|
| **Jump Sound** | `0x248E52` | Played on jump |
| **Pickup Sound** | `0x7003474C` | Played on item collection |

**Function**: `FUN_8001c4a4(entity, sound_id)`

## Key Functions

| Address | Name | Purpose |
|---------|------|---------|
| 0x80070414 | `SpawnProjectileEntity` | Spawn projectile with angle/speed |
| 0x???????? | `InitEntity_168254b5` | Initialize projectile entity |
| 0x800213a8 | `AddEntityToSortedRenderList` | Add to render list |
| 0x800143f0 | `AllocateFromHeap` | Allocate entity memory |

## Godot Implementation

### Projectile Spawning

```gdscript
extends Node2D

const PROJECTILE_SCENE = preload("res://entities/projectile.tscn")

# Constants
const ANGLE_BASE = 3072  # 0xC00
const TRIG_SHIFT = 12
const VELOCITY_SCALE = 1024

func spawn_projectile(player: Node2D, angle: int, speed: int) -> void:
    # Calculate adjusted angle
    var adjusted_angle = ANGLE_BASE - angle
    
    # Calculate velocity (using Godot's trig)
    var angle_rad = adjusted_angle * PI / 2048.0
    var vel_y = sin(angle_rad) * speed / (1 << TRIG_SHIFT)
    var vel_x = cos(angle_rad) * speed / (1 << TRIG_SHIFT)
    
    # Create projectile
    var projectile = PROJECTILE_SCENE.instantiate()
    projectile.position = player.position + Vector2(vel_x, -vel_y)
    projectile.velocity = Vector2(vel_x, -vel_y) * VELOCITY_SCALE
    
    add_child(projectile)
```

### Projectile Entity

```gdscript
extends CharacterBody2D

var velocity := Vector2.ZERO

func _physics_process(delta: float) -> void:
    # Apply velocity (already calculated at spawn)
    var collision = move_and_collide(velocity * delta)
    
    if collision:
        # Hit something - destroy projectile
        queue_free()
    
    # Check if off-screen
    if not get_viewport_rect().has_point(global_position):
        queue_free()
```

## Related Documentation

- [Player Physics](player/player-physics.md) - Player movement and velocity
- [Entities](entities.md) - Entity system overview
- [Collision System](collision.md) - Collision detection
- [Sound System](sound-system.md) - Sound effect playback

