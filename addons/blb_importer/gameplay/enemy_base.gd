extends CharacterBody2D
class_name EnemyBase
## Base class for all enemy types
##
## Implements common enemy behaviors from docs/systems/enemy-ai-overview.md
## Enemy AI patterns:
## 1. Patrol (walk back and forth)
## 2. Chase (follow player when in range)
## 3. Ranged (shoot projectiles)
## 4. Flying (airborne movement patterns)
## 5. Stationary (fixed position, may attack)

enum AIPattern {
	PATROL,
	CHASE,
	RANGED,
	FLYING,
	STATIONARY,
}

enum State {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	STUNNED,
	DYING,
	DEAD,
}

# Enemy properties
@export var ai_pattern := AIPattern.PATROL
@export var health := 3
@export var damage := 1
@export var speed := 60.0  # pixels per second
@export var patrol_distance := 200.0
@export var detection_range := 300.0
@export var attack_range := 100.0
@export var attack_cooldown := 2.0

# State
var current_state := State.IDLE
var patrol_start_x := 0.0
var patrol_direction := 1
var target_player: Node2D = null
var attack_timer := 0.0
var stun_timer := 0.0

# Constants
const GRAVITY := 6.0 * 60.0
const TERMINAL_VELOCITY := 8.0 * 60.0

@onready var animated_sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("enemies")
	patrol_start_x = position.x
	
	# Find player
	get_tree().call_deferred("_find_player")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]


func _physics_process(delta: float) -> void:
	# Handle death
	if current_state == State.DEAD:
		return
	
	# Handle stun
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			current_state = State.IDLE
		return
	
	# Apply gravity for grounded enemies
	if ai_pattern != AIPattern.FLYING:
		if not is_on_floor():
			velocity.y = min(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)
	
	# Update attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# AI behavior
	match ai_pattern:
		AIPattern.PATROL:
			_ai_patrol(delta)
		AIPattern.CHASE:
			_ai_chase(delta)
		AIPattern.RANGED:
			_ai_ranged(delta)
		AIPattern.FLYING:
			_ai_flying(delta)
		AIPattern.STATIONARY:
			_ai_stationary(delta)
	
	# Move
	move_and_slide()
	
	# Update animation
	_update_animation()


func _ai_patrol(delta: float) -> void:
	## Patrol AI: Walk back and forth
	current_state = State.PATROLLING
	
	# Check patrol bounds
	var distance_from_start := abs(position.x - patrol_start_x)
	if distance_from_start >= patrol_distance:
		patrol_direction *= -1
	
	# Move
	velocity.x = patrol_direction * speed
	
	# Check for player in detection range
	if target_player and _is_player_in_range(detection_range):
		ai_pattern = AIPattern.CHASE


func _ai_chase(delta: float) -> void:
	## Chase AI: Follow player
	current_state = State.CHASING
	
	if not target_player:
		ai_pattern = AIPattern.PATROL
		return
	
	# Calculate direction to player
	var direction := sign(target_player.global_position.x - global_position.x)
	velocity.x = direction * speed * 1.5  # Chase slightly faster
	
	# Check if player escaped
	if not _is_player_in_range(detection_range * 1.5):
		ai_pattern = AIPattern.PATROL
	
	# Check attack range
	if _is_player_in_range(attack_range):
		_attack()


func _ai_ranged(delta: float) -> void:
	## Ranged AI: Shoot projectiles at player
	current_state = State.IDLE
	
	if not target_player:
		return
	
	# Face player
	var direction := sign(target_player.global_position.x - global_position.x)
	patrol_direction = direction
	
	# Attack if in range and cooldown ready
	if _is_player_in_range(attack_range) and attack_timer <= 0:
		_attack()


func _ai_flying(delta: float) -> void:
	## Flying AI: Airborne movement
	# Simple sine wave pattern
	velocity.x = cos(Time.get_ticks_msec() * 0.001) * speed
	velocity.y = sin(Time.get_ticks_msec() * 0.002) * speed * 0.5
	
	# Chase player if in range
	if target_player and _is_player_in_range(detection_range):
		var direction := (target_player.global_position - global_position).normalized()
		velocity = direction * speed


func _ai_stationary(delta: float) -> void:
	## Stationary AI: Stay in place, attack when in range
	current_state = State.IDLE
	velocity.x = 0
	
	if not target_player:
		return
	
	# Face player
	var direction := sign(target_player.global_position.x - global_position.x)
	patrol_direction = direction
	
	# Attack if in range
	if _is_player_in_range(attack_range) and attack_timer <= 0:
		_attack()


func _is_player_in_range(range: float) -> bool:
	if not target_player:
		return false
	return global_position.distance_to(target_player.global_position) <= range


func _attack() -> void:
	## Execute attack (to be overridden by subclasses)
	current_state = State.ATTACKING
	attack_timer = attack_cooldown


func _update_animation() -> void:
	if not animated_sprite:
		return
	
	# Flip sprite
	animated_sprite.flip_h = patrol_direction < 0
	
	# Play animation
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.PATROLLING, State.CHASING:
			animated_sprite.play("walk")
		State.ATTACKING:
			animated_sprite.play("attack")
		State.STUNNED:
			animated_sprite.play("stun")
		State.DYING:
			animated_sprite.play("death")


func take_damage(amount: int, from_direction: Vector2 = Vector2.ZERO) -> void:
	## Handle enemy taking damage
	health -= amount
	
	if health <= 0:
		_die()
	else:
		# Knockback
		if from_direction != Vector2.ZERO:
			velocity = from_direction * 200.0
		
		# Brief stun
		stun_timer = 0.3
		current_state = State.STUNNED


func _die() -> void:
	## Handle enemy death
	current_state = State.DYING
	
	# Stop movement
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	# Play death animation
	if animated_sprite:
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	current_state = State.DEAD
	
	# Remove from scene
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	## Handle collision with player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

