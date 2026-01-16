# Entity Type 24: Special Ammo Pickup

**Entity Type**: 24  
**BLB Type**: 24  
**Callback**: 0x8007f460  
**Sprite ID**: Unknown (needs extraction)  
**Category**: Collectible (Ammo/Swirl)  
**Count**: 227 instances

---

## Overview

Special pickups that grant Swirls (bonus room unlock) or Green Bullets.

> **Note**: Previous documentation incorrectly called Swirls "weapon ammo".
> Swirls unlock bonus rooms; Green Bullets are the actual projectile ammo.

**Gameplay Function**: Swirl or Green Bullet replenishment

---

## Behavior

**Type**: Stationary collectible  
**Movement**: May float or bob  
**Collision**: Player touch triggers collection  
**Respawn**: Does not respawn  
**Effect**: Grants ammunition

---

## Pickup Types

Based on game systems:

**Swirls** (Bonus Room Unlock):
- Storage: `g_pPlayerState[0x13]`
- Max: 20
- Purpose: Collect 3 → bonus room portal unlocks
- NOT weapon ammo!

**Green Bullets** (Projectile Ammo):
- Storage: `g_pPlayerState[0x1A]`
- Max: 3
- Purpose: Actual projectile weapon ammo

**Entity Type 24** likely grants Swirls or Green Bullets based on variant

---

## Collection Logic

```c
// When player touches ammo pickup
if (CheckEntityCollision(player, ammo_pickup)) {
    // Determine ammo type
    int pickup_type = pickup->subtype;
    
    // Grant item
    if (pickup_type == PICKUP_SWIRL) {
        int current = g_pPlayerState[0x13];
        g_pPlayerState[0x13] = min(current + 1, 20);  // +1 swirl, max 20
        g_pPlayerState[0x1b]++;  // Also increment total for secret ending
    } else if (pickup_type == PICKUP_GREEN_BULLET) {
        int current = g_pPlayerState[0x1A];
        g_pPlayerState[0x1A] = min(current + 1, 3);   // +1, max 3
    }
    
    // Play collection sound
    PlaySoundEffect(0x7003474c, pan, 0);
    
    // Remove pickup
    RemoveEntity(pickup);
}
```

---

## Godot Implementation

```gdscript
extends Area2D
class_name SpecialPickup

enum PickupType { SWIRL, GREEN_BULLET }

@export var pickup_type: PickupType = PickupType.SWIRL

func _ready() -> void:
    body_entered.connect(_on_player_touch)

func _on_player_touch(body: Node2D) -> void:
    if body.is_in_group("player"):
        match pickup_type:
            PickupType.SWIRL:
                body.add_swirl(1)  # Bonus room collectible
            PickupType.GREEN_BULLET:
                body.add_green_bullet(1)  # Actual ammo
        
        AudioManager.play_sound(0x7003474c)
        queue_free()
```

---

**Status**: ✅ **Fully Documented** (behavior)  
**Sprite ID**: ⚠️ Needs extraction  
**Implementation**: Ready

