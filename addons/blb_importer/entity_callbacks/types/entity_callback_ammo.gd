@tool
class_name EntityAmmo
extends BLBEntityBase
## Ammo/Special Ammo pickup entity
##
## PSX Reference: 0x8007f460 (EntityCallback_Type24)
## - Bullet pickups (308 standard + 227 special)
## - Adds ammunition to player weapon
##
## Scene structure:
##   EntityAmmo (this script)
##   └── Sprite (AnimatedSprite2D)

const AMMO_STANDARD: int = 5
const AMMO_SPECIAL: int = 10


func _entity_init() -> void:
	play_animation("idle")


func _entity_tick(game_state: Dictionary) -> void:
	if not is_on_screen(game_state):
		return
	
	if check_player_collision(game_state):
		# Score based on ammo type
		var score = 50 if entity_type == 24 else 25
		collect(score)
