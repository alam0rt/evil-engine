# Entity Type 3: Swirl Pickup

**Entity Type**: 3  
**BLB Type**: 3  
**Callback**: 0x8007efd0 (shared with types 0, 4)  
**Sprite ID**: Unknown (needs extraction)  
**Category**: Collectible (Bonus Room Unlock)  
**Count**: 308 instances (very common!)

---

## Overview

Swirl pickups that unlock bonus rooms when 3 are collected.

> **CORRECTION**: Previous documentation incorrectly called these "Swirly Q ammo".
> Swirls are NOT weapon ammunition - they unlock bonus room portals.

**Gameplay Function**: Collect 3 Swirls to unlock bonus room portal

---

## Behavior

**Type**: Stationary collectible  
**Movement**: May float/bob slightly  
**Collision**: Player touch triggers collection  
**Respawn**: Does not respawn  
**Animation**: Rotating or idle animation

---

## Collection Logic

```c
// When player touches swirl pickup
if (CheckEntityCollision(player, swirl_pickup)) {
    // Grant swirl for bonus room
    int current = g_pPlayerState[0x13];  // Swirl count
    g_pPlayerState[0x13] = min(current + 1, 20);  // +1, max 20
    g_pPlayerState[0x1b]++;  // Also increment total (for secret ending)
    
    // Play collection sound
    PlaySoundEffect(0x7003474c, pan, 0);
    
    // Remove pickup
    RemoveEntity(swirl_pickup);
}
```

**Storage**: `g_pPlayerState[0x13]` (Swirl count)  
**Max**: 20  
**Amount**: +1 per pickup

---

## Godot Implementation

```gdscript
extends Area2D
class_name SwirlPickup

const MAX_SWIRLS = 20

func _on_player_touch(body: Node2D) -> void:
    if body.is_in_group("player"):
        # Grant swirl (bonus room collectible)
        var current = body.swirl_count
        body.swirl_count = min(current + 1, MAX_SWIRLS)
        body.total_swirls += 1  # For secret ending
        
        # Sound and remove
        AudioManager.play_sound(0x7003474c)
        queue_free()
```

---

**Status**: ✅ **Fully Documented** (behavior)  
**Sprite ID**: ⚠️ Needs extraction  
**Implementation**: Ready

