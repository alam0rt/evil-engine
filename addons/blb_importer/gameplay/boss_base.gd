extends CharacterBody2D
class_name BossBase
## Base class for all boss entities
##
## Based on docs/systems/boss-ai/boss-behaviors.md and boss-system-analysis.md
## 
## Boss System (from docs):
## - 5 bosses total (MEGA, HEAD, GLEN, WIZZ, KLOG)
## - Multi-entity structure: 9 entities per boss
## - HP: 5 default (stored in g_pPlayerState[0x1D])
## - Multi-phase combat based on HP
## - Destructible parts system

signal boss_damaged(new_hp: int)
signal boss_defeated()
signal phase_changed(new_phase: int)

enum Phase {
	PHASE_1,  # HP: 5 (slow, simple patterns)
	PHASE_2,  # HP: 3-4 (medium difficulty)
	PHASE_3,  # HP: 1-2 (fast, aggressive, special attacks)
}

enum State {
	IDLE,
	TELEGRAPHING,
	ATTACKING,
	RECOVERING,
	STUNNED,
	DYING,
	DEAD,
}

# Boss properties
@export var boss_name := "Boss"
@export var max_health := 5  # Default HP (from docs)
@export var invulnerable := false

# State
var current_health := 5
var current_phase := Phase.PHASE_1
var current_state := State.IDLE

# Attack system
var attack_timer := 0.0
var recovery_timer := 0.0
var telegraph_timer := 0.0

# Attack intervals by phase (from docs/systems/boss-ai/boss-behaviors.md)
var phase_attack_intervals := {
	Phase.PHASE_1: 2.0,   # 120 frames @ 60 FPS
	Phase.PHASE_2: 1.5,   # 90 frames
	Phase.PHASE_3: 1.0,   # 60 frames
}

var phase_speeds := {
	Phase.PHASE_1: 1.0,
	Phase.PHASE_2: 1.5,
	Phase.PHASE_3: 2.0,
}

# Boss parts (6 destructible parts from docs)
var boss_parts: Array[Node2D] = []
const BOSS_PART_COUNT := 6

# Player reference
var target_player: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")  # Bosses are enemies too
	
	current_health = max_health
	_update_phase()
	
	# Find player
	call_deferred("_find_player")
	
	# Create boss parts
	call_deferred("_create_boss_parts")


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]


func _create_boss_parts() -> void:
	## Create 6 boss part entities
	## From docs: Each boss has 6 destructible parts with sprite 0x8818a018
	## Parts positioned using offset tables @ 0x8009b860
	
	# Simplified part creation (exact offsets need table extraction)
	var part_positions := [
		Vector2(-40, -30),
		Vector2(40, -30),
		Vector2(-60, 0),
		Vector2(60, 0),
		Vector2(-40, 30),
		Vector2(40, 30),
	]
	
	for i in range(BOSS_PART_COUNT):
		var part = Area2D.new()
		part.name = "BossPart_%d" % i
		part.position = part_positions[i]
		
		# Add collision
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(24, 24)
		collision.shape = shape
		part.add_child(collision)
		
		# Add to boss
		add_child(part)
		boss_parts.append(part)


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	if recovery_timer > 0:
		recovery_timer -= delta
	if telegraph_timer > 0:
		telegraph_timer -= delta
	
	# State machine
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.TELEGRAPHING:
			_state_telegraph(delta)
		State.ATTACKING:
			_state_attack(delta)
		State.RECOVERING:
			_state_recover(delta)
		State.STUNNED:
			_state_stunned(delta)
		State.DYING:
			_state_dying(delta)
	
	# Update animation
	_update_animation()


func _state_idle(delta: float) -> void:
	## Idle state - waiting for next attack
	if attack_timer <= 0:
		_start_attack()


func _state_telegraph(delta: float) -> void:
	## Telegraph state - warning before attack
	if telegraph_timer <= 0:
		current_state = State.ATTACKING


func _state_attack(delta: float) -> void:
	## Attack state - execute attack pattern
	# Override in subclasses
	pass


func _state_recover(delta: float) -> void:
	## Recovery state - cooldown after attack
	if recovery_timer <= 0:
		current_state = State.IDLE
		attack_timer = _get_attack_interval()


func _state_stunned(delta: float) -> void:
	## Stunned state - temporarily disabled
	pass


func _state_dying(delta: float) -> void:
	## Dying state - death animation
	pass


func _start_attack() -> void:
	## Start attack sequence
	current_state = State.TELEGRAPHING
	telegraph_timer = 0.5  # Half second warning


func _get_attack_interval() -> float:
	## Get attack interval for current phase
	return phase_attack_intervals.get(current_phase, 2.0)


func _update_phase() -> void:
	## Update phase based on HP (from docs)
	var old_phase = current_phase
	
	if current_health >= 5:
		current_phase = Phase.PHASE_1
	elif current_health >= 3:
		current_phase = Phase.PHASE_2
	else:
		current_phase = Phase.PHASE_3
	
	if old_phase != current_phase:
		phase_changed.emit(current_phase)
		print("[Boss] Phase changed to ", current_phase)


func _update_animation() -> void:
	if not animated_sprite:
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.TELEGRAPHING:
			animated_sprite.play("telegraph")
		State.ATTACKING:
			animated_sprite.play("attack")
		State.RECOVERING:
			animated_sprite.play("recover")
		State.STUNNED:
			animated_sprite.play("stun")
		State.DYING:
			animated_sprite.play("death")


func take_damage(amount: int, from_direction: Vector2 = Vector2.ZERO) -> void:
	## Handle boss taking damage
	## From docs: Boss HP stored in g_pPlayerState[0x1D]
	
	if invulnerable or current_state == State.DYING:
		return
	
	current_health -= amount
	boss_damaged.emit(current_health)
	
	print("[Boss] Took %d damage! HP: %d/%d" % [amount, current_health, max_health])
	
	# Update phase
	_update_phase()
	
	# Check defeat
	if current_health <= 0:
		_defeat()
	else:
		# Brief stun
		current_state = State.STUNNED
		await get_tree().create_timer(0.5).timeout
		current_state = State.IDLE


func _defeat() -> void:
	## Handle boss defeat
	current_state = State.DYING
	current_health = 0
	
	# Disable collision
	set_physics_process(false)
	
	# Play death animation
	if animated_sprite:
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	current_state = State.DEAD
	boss_defeated.emit()
	
	# Notify game manager
	get_tree().call_group("game_manager", "on_boss_defeated", boss_name)
	
	# Remove boss
	queue_free()

