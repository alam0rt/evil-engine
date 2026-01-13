@tool
class_name EntityPortal
extends BLBEntityBase
## Portal/Warp entity
##
## PSX Reference: 0x80080ddc (shared by types 42-44, 53-55, 60)
##
## Portal behavior:
## - Warp to another location or stage
## - Trigger on player contact
## - Some are exit portals, some are stage transitions
##
## Scene structure:
##   EntityPortal (this script)
##   └── Sprite (AnimatedSprite2D)

## Portal types
enum PortalType {
	STAGE_EXIT = 42,      # End of stage
	HIDDEN_EXIT = 43,     # Secret exit
	BONUS_PORTAL = 44,    # Bonus area entrance
	WARP_POINT = 53,      # Teleport within stage
}


func _entity_init() -> void:
	# Portals may have an entrance animation
	play_animation("idle")


func _entity_tick(game_state: Dictionary) -> void:
	if not is_on_screen(game_state):
		return
	
	# Check if player entered portal
	if check_player_collision(game_state):
		_activate_portal()


func _activate_portal() -> void:
	# Emit signal with destination (variant encodes where to go)
	portal_activated.emit(self, variant)
