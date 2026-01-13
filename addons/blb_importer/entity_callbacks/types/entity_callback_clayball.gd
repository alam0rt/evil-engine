@tool
class_name EntityClayball
extends BLBEntityBase
## Clayball (collectible coin) entity
##
## PSX Reference: 0x80080328 (EntityCallback_Type02)
## - Most common entity type (5,727 instances)
## - Collectible coin that adds to score
## - Simple collision detection with player
##
## Scene structure:
##   EntityClayball (this script)
##   └── Sprite (AnimatedSprite2D)

## Score value for collecting
const SCORE_VALUE: int = 100


func _entity_init() -> void:
	# Start idle animation
	play_animation("idle")


func _entity_tick(game_state: Dictionary) -> void:
	# Only process if near screen (with margin for activation)
	if not is_on_screen(game_state):
		return
	
	# Check collision with player
	if check_player_collision(game_state):
		collect(SCORE_VALUE)
