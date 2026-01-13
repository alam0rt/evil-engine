@tool
class_name EntityEnemy
extends BLBEntityBase
## Enemy entity
##
## PSX Reference:
## - Type 25: 0x800805c8 (EntityCallback_Type25 - EnemyA)
## - Type 27: 0x8007f354 (EntityCallback_Type27 - EnemyB)
##
## Basic enemy behavior:
## - Patrol between bounds
## - Face player when in range
## - Hurt player on contact
## - Die when hit by player attack
##
## Scene structure:
##   EntityEnemy (this script)
##   └── Sprite (AnimatedSprite2D)

## States
enum EnemyState {
	IDLE = 0,
	PATROL = 1,
	CHASE = 2,
	ATTACK = 3,
	HURT = 4,
	DEAD = 5,
}

## Movement speed
const PATROL_SPEED: float = 1.0
const CHASE_SPEED: float = 2.0

## Detection range for chasing
const DETECTION_RANGE: float = 128.0

## Attack cooldown frames
const ATTACK_COOLDOWN: int = 60


func _entity_init() -> void:
	state = EnemyState.PATROL
	direction = 1  # Start moving right
	health = 1
	
	play_animation("walk")


func _entity_tick(game_state: Dictionary) -> void:
	if not is_on_screen(game_state):
		# Off-screen enemies pause
		return
	
	match state:
		EnemyState.PATROL:
			_tick_patrol()
		EnemyState.CHASE:
			_tick_chase(game_state)
		EnemyState.ATTACK:
			_tick_attack()
		EnemyState.HURT:
			_tick_hurt()
		EnemyState.DEAD:
			return
	
	# Check if player is in attack range
	if state != EnemyState.DEAD:
		if check_player_collision(game_state):
			# Emit signal to hurt player (loose coupling)
			player_damaged.emit(self, 1)


func _tick_patrol() -> void:
	# Move in current direction
	var new_x = position.x + direction * PATROL_SPEED
	
	# Reverse at bounds
	if new_x <= bounds.position.x or new_x >= bounds.position.x + bounds.size.x:
		direction *= -1
		new_x = position.x + direction * PATROL_SPEED
	
	position.x = new_x
	
	# Flip sprite
	if sprite:
		sprite.flip_h = direction < 0


func _tick_chase(game_state: Dictionary) -> void:
	var player_x: float = game_state.get("player_x", 0)
	
	# Move toward player
	if player_x < position.x:
		direction = -1
	else:
		direction = 1
	
	position.x += direction * CHASE_SPEED
	
	# Flip sprite
	if sprite:
		sprite.flip_h = direction < 0


func _tick_attack() -> void:
	# Play attack animation and wait for cooldown
	if timer_tick(ATTACK_COOLDOWN):
		state = EnemyState.PATROL


func _tick_hurt() -> void:
	# Brief stun
	if timer_tick(15):
		state = EnemyState.PATROL
