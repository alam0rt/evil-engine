@tool
class_name EntityItem
extends BLBEntityBase
## Item pickup entity
##
## PSX Reference: 0x80081504 (EntityCallback_Type08)
## - Generic item pickup (144 instances)
## - Includes power-ups, lives, etc.
## - Variant field determines item type
##
## Scene structure:
##   EntityItem (this script)
##   └── Sprite (AnimatedSprite2D)

## Item types by variant
enum ItemType {
	GENERIC = 0,
	EXTRA_LIFE = 1,
	UNIVERSE = 2,      # Swirl collectible
	SPEED_BOOST = 3,
	INVINCIBILITY = 4,
}

## Score values by type
const SCORE_VALUES: Dictionary = {
	ItemType.GENERIC: 500,
	ItemType.EXTRA_LIFE: 0,  # No score, adds life
	ItemType.UNIVERSE: 1000,
	ItemType.SPEED_BOOST: 200,
	ItemType.INVINCIBILITY: 200,
}


func _entity_init() -> void:
	play_animation("idle")


func _entity_tick(game_state: Dictionary) -> void:
	if not is_on_screen(game_state):
		return
	
	if check_player_collision(game_state):
		var item_type = variant % 5
		var score = SCORE_VALUES.get(item_type, 500)
		collect(score)
