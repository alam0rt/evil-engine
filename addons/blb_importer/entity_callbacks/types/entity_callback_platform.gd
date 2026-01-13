@tool
class_name EntityPlatform
extends BLBEntityBase
## Moving platform entity
##
## PSX Reference:
## - Type 28: 0x80080638 (EntityCallback_Type28 - PlatformA)
## - Type 48: 0x80080e4c (EntityCallback_Type48 - PlatformB)
##
## Platform behavior:
## - Move between two points (bounds define path)
## - Player can stand on top
## - Some platforms fall when stepped on
##
## Scene structure:
##   EntityPlatform (this script)
##   └── Sprite (AnimatedSprite2D)

## Platform types
enum PlatformType {
	HORIZONTAL = 0,  # Moves left/right
	VERTICAL = 1,    # Moves up/down
	FALLING = 2,     # Falls when player touches
	ROTATING = 3,    # Rotates around center
}

## Movement speed (pixels per frame)
const MOVE_SPEED: float = 1.5

## Pause at endpoints (frames)
const ENDPOINT_PAUSE: int = 30

## Fall acceleration
const FALL_GRAVITY: float = 0.3

## States
enum PlatformState {
	MOVING = 0,
	PAUSED = 1,
	FALLING = 2,
}


func _entity_init() -> void:
	state = PlatformState.MOVING
	direction = 1  # Start moving positive direction


func _entity_tick(game_state: Dictionary) -> void:
	# Platforms process even off-screen (to maintain sync)
	
	var platform_type = variant % 4
	
	match platform_type:
		PlatformType.HORIZONTAL:
			_tick_horizontal()
		PlatformType.VERTICAL:
			_tick_vertical()
		PlatformType.FALLING:
			_tick_falling(game_state)
		PlatformType.ROTATING:
			_tick_rotating()


func _tick_horizontal() -> void:
	if state == PlatformState.PAUSED:
		if timer_tick(ENDPOINT_PAUSE):
			state = PlatformState.MOVING
		return
	
	var new_x = position.x + direction * MOVE_SPEED
	
	# Reverse at bounds
	if new_x <= bounds.position.x:
		new_x = bounds.position.x
		direction = 1
		state = PlatformState.PAUSED
	elif new_x >= bounds.position.x + bounds.size.x:
		new_x = bounds.position.x + bounds.size.x
		direction = -1
		state = PlatformState.PAUSED
	
	position.x = new_x


func _tick_vertical() -> void:
	if state == PlatformState.PAUSED:
		if timer_tick(ENDPOINT_PAUSE):
			state = PlatformState.MOVING
		return
	
	var new_y = position.y + direction * MOVE_SPEED
	
	# Reverse at bounds
	if new_y <= bounds.position.y:
		new_y = bounds.position.y
		direction = 1
		state = PlatformState.PAUSED
	elif new_y >= bounds.position.y + bounds.size.y:
		new_y = bounds.position.y + bounds.size.y
		direction = -1
		state = PlatformState.PAUSED
	
	position.y = new_y


func _tick_falling(game_state: Dictionary) -> void:
	if state == PlatformState.FALLING:
		# Accelerate downward
		vel_y += FALL_GRAVITY
		position.y += vel_y
		
		# Deactivate when off screen
		var cam_y = game_state.get("camera_y", 0)
		if position.y > cam_y + 300:
			active = false
		return
	
	# Check if player is standing on platform
	if check_player_collision(game_state):
		# Start falling after brief delay
		if timer_tick(15):
			state = PlatformState.FALLING
			vel_y = 0


func _tick_rotating() -> void:
	# Rotate around center point
	var angle = timer * 0.02
	var radius = 32.0  # Could get from bounds
	var center = bounds.get_center()
	
	position.x = center.x + cos(angle) * radius
	position.y = center.y + sin(angle) * radius
	
	timer += 1
