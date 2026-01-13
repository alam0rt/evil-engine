@tool
class_name EntityMessage
extends BLBEntityBase
## Message/Save box entity
##
## PSX Reference: 0x80080f1c (EntityCallback_Type45)
##
## Message behavior:
## - Display text/hint when player approaches
## - Some are save points (checkpoints)
##
## Scene structure:
##   EntityMessage (this script)
##   └── Sprite (AnimatedSprite2D)

const ACTIVATION_DISTANCE: float = 48.0


func _entity_init() -> void:
	play_animation("idle")


func _entity_tick(game_state: Dictionary) -> void:
	if not is_on_screen(game_state):
		return
	
	# Check if player is close enough to activate
	var distance = distance_to_player(game_state)
	
	if distance < ACTIVATION_DISTANCE:
		if state == 0:  # Not yet activated
			_activate_message()
	else:
		if state == 1:  # Was activated, player left
			_deactivate_message()


func _activate_message() -> void:
	state = 1
	
	# Emit signal with message ID (variant encodes which message)
	message_triggered.emit(self, variant)
	
	# Play activation animation
	play_animation("active")


func _deactivate_message() -> void:
	state = 0
	play_animation("idle")
