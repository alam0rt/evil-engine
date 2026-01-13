@tool
class_name EntityDefault
extends BLBEntityBase
## Default entity for unknown/unused types
##
## PSX Reference: 0x8007efd0 (shared by types 0, 3, 4)
## Does minimal processing - entity just exists and may animate
##
## Scene structure:
##   EntityDefault (this script)
##   └── Sprite (AnimatedSprite2D) [optional]


func _entity_init() -> void:
	# Default entities have no special initialization
	pass


func _entity_tick(game_state: Dictionary) -> void:
	# Only process if on screen
	if not is_on_screen(game_state):
		return
	
	# Just update visibility based on active state
	visible = active
