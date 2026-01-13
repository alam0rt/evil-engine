@tool
class_name EntityBoss
extends BLBEntityBase
## Boss entity
##
## PSX Reference:
## - Type 50: 0x8007fc20 (EntityCallback_Type50 - Boss main)
## - Type 51: 0x8007fc9c (EntityCallback_Type51 - Boss part)
##
## Boss behavior is complex and level-specific.
## This is a framework for boss implementation.
##
## Scene structure:
##   EntityBoss (this script)
##   └── Sprite (AnimatedSprite2D)

## Boss states
enum BossState {
	IDLE = 0,
	INTRO = 1,
	PHASE_1 = 2,
	PHASE_2 = 3,
	PHASE_3 = 4,
	DYING = 5,
	DEAD = 6,
}

## Default health per phase
const PHASE_HEALTH: int = 3

## Is this a boss part (sub-entity)?
var is_part: bool = false
var invincible: bool = false
var phase: int = 0


func _entity_init() -> void:
	state = BossState.IDLE
	health = PHASE_HEALTH * 3  # Total health
	phase = 0
	invincible = false
	
	# Boss parts link to main boss
	if entity_type == 51:
		is_part = true


func _entity_tick(game_state: Dictionary) -> void:
	# Boss is always processed when on screen
	if not is_on_screen(game_state):
		return
	
	match state:
		BossState.IDLE:
			_tick_idle(game_state)
		BossState.INTRO:
			_tick_intro()
		BossState.PHASE_1, BossState.PHASE_2, BossState.PHASE_3:
			_tick_combat(game_state)
		BossState.DYING:
			_tick_dying()
		BossState.DEAD:
			return


func _tick_idle(game_state: Dictionary) -> void:
	# Wait for player to approach
	if distance_to_player(game_state) < 160:
		state = BossState.INTRO
		play_animation("intro")


func _tick_intro() -> void:
	# Play intro animation/cutscene
	if timer_tick(120):  # 2 seconds at 60fps
		state = BossState.PHASE_1
		play_animation("idle")


func _tick_combat(game_state: Dictionary) -> void:
	# Basic combat pattern
	# Override in level-specific boss scripts
	
	# Check player collision for damage
	if check_player_collision(game_state) and not invincible:
		player_damaged.emit(self, 1)
	
	# Update phase based on health
	var total_health = PHASE_HEALTH * 3
	
	if health <= total_health / 3:
		state = BossState.PHASE_3
	elif health <= total_health * 2 / 3:
		state = BossState.PHASE_2


func _tick_dying() -> void:
	# Death animation
	if timer_tick(120):
		state = BossState.DEAD
		active = false
		entity_killed.emit(self)
