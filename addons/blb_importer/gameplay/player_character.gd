extends CharacterBody2D
class_name PlayerCharacter
## Skullmonkeys Player Character - Klaymen
##
## Implements faithful recreation of player physics and controls from the original game.
## Based on docs/systems/player/player-physics.md and docs/PHYSICS_QUICK_REFERENCE.md
##
## Physics Constants (CODE-VERIFIED from Ghidra @ lines 31759-32919):
## - Walk speeds: 2.0 px/frame (normal), 3.0 px/frame (run)
## - Jump velocity: -2.25 px/frame
## - Gravity: -6.0 px/frame²
## - Terminal velocity: 8.0 px/frame (observed)
## - Landing cushion: -0.07 px/frame
## - Bounce velocity: -2.25 px/frame

# Physics constants from original game (Ghidra-verified)
const WALK_SPEED := 2.0 * 60.0  # Convert frame-based to pixels/second (60 FPS)
const RUN_SPEED := 3.0 * 60.0
const JUMP_VELOCITY := -2.25 * 60.0
const GRAVITY := 6.0 * 60.0  # Positive in Godot (down is positive Y)
const TERMINAL_VELOCITY := 8.0 * 60.0
const LANDING_CUSHION := 0.07 * 60.0
const BOUNCE_VELOCITY := -2.25 * 60.0

# Player state
enum State {
	IDLE,
	WALKING,
	RUNNING,
	JUMPING,
	FALLING,
	LANDING,
	DEAD,
}

var current_state := State.IDLE
var facing_direction := 1  # 1 = right, -1 = left
var is_running := false

# Player state structure (from docs/systems/player/player-system.md)
# Mirrors g_pPlayerState @ 0x8009DC20
var lives := 5                    # +0x11: Current lives (default 5)
var orb_count := 0                # +0x12: Clay/orb count (100 → 1up, then reset to 0)
var checkpoint_count := 0         # +0x13: Checkpoint/swirl count (3 → bonus room)
var phoenix_hands := 0            # +0x14: Bird powerup (max 7)
var phart_heads := 0              # +0x15: Head powerup (max 7)
var universe_enemas := 0          # +0x16: Fart Clone powerup (max 7)
var powerup_flags := 0            # +0x17: Active powerups (bit 0x01=Halo, 0x02=Trail)
var shrink_mode := false          # +0x18: Mini mode active
var icon_1970_count := 0          # +0x19: "1970" icons (max 3)
var green_bullets := 0            # +0x1A: Energy Ball count (max 3)
var super_willies := 0            # +0x1C: Super Power count (max 7)

# Combat state
var invincibility_frames := 0
const INVINCIBILITY_DURATION := 120  # ~2 seconds at 60 FPS

# Weapon system
var weapon_system: Node = null

# Sound IDs (from docs/systems/sound-effects-reference.md)
const SOUND_JUMP := 0x64221e61
const SOUND_LAND := 0x5860c640
const SOUND_COLLECT := 0x7003474c
const SOUND_ONE_UP := 0x40e28045  # Powerup sound (closest to 1-up)
const SOUND_HALO_ACTIVATE := 0xe0880448

# Animation state
@onready var animated_sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	# Add to player group
	add_to_group("player")
	
	# Set up collision
	set_motion_mode(MOTION_MODE_GROUNDED)
	set_floor_stop_on_slope_enabled(true)
	set_floor_snap_length(4.0)
	
	# Setup weapon system
	_setup_weapon_system()


func _physics_process(delta: float) -> void:
	# Handle invincibility frames
	if invincibility_frames > 0:
		invincibility_frames -= 1
		# Flash sprite during invincibility
		modulate.a = 0.5 if (invincibility_frames % 10) < 5 else 1.0
	else:
		modulate.a = 1.0
	
	# Handle death state
	if current_state == State.DEAD:
		_handle_death()
		return
	
	# Get input
	var input_direction := Input.get_axis("move_left", "move_right")
	is_running = Input.is_action_pressed("run")
	
	# Update facing direction
	if input_direction != 0:
		facing_direction = sign(input_direction)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)
		if velocity.y > 0 and current_state != State.FALLING:
			current_state = State.FALLING
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMPING
		
		# Play jump sound (from docs/systems/sound-effects-reference.md)
		get_tree().call_group("audio_manager", "play_sound", SOUND_JUMP)
	
	# Handle movement
	var target_speed := 0.0
	if input_direction != 0:
		target_speed = RUN_SPEED if is_running else WALK_SPEED
		target_speed *= input_direction
		
		if is_on_floor():
			current_state = State.RUNNING if is_running else State.WALKING
	else:
		if is_on_floor() and current_state not in [State.JUMPING, State.LANDING]:
			current_state = State.IDLE
	
	# Apply movement
	velocity.x = target_speed
	
	# Handle landing
	if is_on_floor() and current_state == State.FALLING:
		current_state = State.LANDING
		# Landing cushion effect (slight downward velocity reduction)
		velocity.y = LANDING_CUSHION
		
		# Play landing sound (from docs/systems/sound-effects-reference.md)
		get_tree().call_group("audio_manager", "play_sound", SOUND_LAND)
	
	# Move character
	move_and_slide()
	
	# Handle attack input
	_handle_attack()
	
	# Update animation
	_update_animation()


func _update_animation() -> void:
	if not animated_sprite:
		return
	
	# Flip sprite based on direction
	animated_sprite.flip_h = facing_direction < 0
	
	# Set animation based on state
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALKING:
			animated_sprite.play("walk")
		State.RUNNING:
			animated_sprite.play("run")
		State.JUMPING:
			animated_sprite.play("jump")
		State.FALLING:
			animated_sprite.play("fall")
		State.LANDING:
			animated_sprite.play("land")
		State.DEAD:
			animated_sprite.play("death")


func take_damage(amount: int = 1, from_direction: Vector2 = Vector2.ZERO) -> void:
	## Handle player taking damage
	## Based on docs/systems/combat-system.md and docs/systems/damage-system-complete.md
	
	# Check invincibility
	if invincibility_frames > 0:
		return
	
	# Check halo protection (bit 0x01 of powerup_flags)
	if powerup_flags & 0x01:
		# Halo absorbs one hit
		powerup_flags &= ~0x01  # Clear halo bit
		
		# Play powerup end sound
		get_tree().call_group("audio_manager", "play_sound", SOUND_ONE_UP)
		
		# Remove visual effect
		modulate = Color.WHITE
		
		print("[Player] Halo absorbed damage!")
		return
	
	# Apply damage
	lives -= amount
	
	if lives <= 0:
		_die()
	else:
		# Start invincibility period
		invincibility_frames = INVINCIBILITY_DURATION
		
		# Apply knockback (from docs: ±2 horizontal, -3 vertical)
		var knockback_dir = -facing_direction if from_direction == Vector2.ZERO else -sign(from_direction.x)
		velocity.x = knockback_dir * 2.0 * 60.0
		velocity.y = -3.0 * 60.0
		
		# Update HUD
		get_tree().call_group("hud", "set_lives", lives)
		
		print("[Player] Took damage! Lives: %d" % lives)


func _die() -> void:
	## Handle player death
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
	# Emit death signal for game manager
	get_tree().call_group("game_manager", "on_player_death")


func _handle_death() -> void:
	## Death animation and respawn handling
	# Wait for death animation to complete
	if animated_sprite and animated_sprite.is_playing():
		return
	
	# Request respawn from checkpoint
	get_tree().call_group("game_manager", "respawn_player")


func respawn(spawn_position: Vector2) -> void:
	## Respawn player at checkpoint or spawn point
	position = spawn_position
	velocity = Vector2.ZERO
	current_state = State.IDLE
	invincibility_frames = INVINCIBILITY_DURATION


func bounce() -> void:
	## Bounce off enemy/object (from docs: -2.25 px/frame)
	velocity.y = BOUNCE_VELOCITY


func _setup_weapon_system() -> void:
	## Setup weapon system for player
	var WeaponSystem = load("res://addons/blb_importer/gameplay/projectile_system.gd").WeaponSystem
	weapon_system = WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	add_child(weapon_system)
	weapon_system.ammo_standard = 0  # Start with no ammo (must collect)


func collect_clayball() -> void:
	## Collect a clayball (primary collectible)
	## From docs/systems/enemies/type-002-clayball.md and docs/reference/items.md:
	## - Increments g_pPlayerState[0x12] (orb_count)
	## - When orb_count reaches 100: grant 1-up, reset counter to 0
	## - Sound: 0x7003474c
	
	# Increment counter
	orb_count += 1
	
	# Update HUD
	get_tree().call_group("hud", "set_clayballs", orb_count)
	
	# Check for 1-up (100 clayballs)
	if orb_count >= 100:
		grant_extra_life()
		orb_count = 0  # Reset counter
		
		# Update HUD
		get_tree().call_group("hud", "set_clayballs", orb_count)
	
	print("[Player] Collected clayball: %d/100" % orb_count)


func grant_extra_life() -> void:
	## Grant an extra life
	## From docs: g_pPlayerState[0x11]++ (lives)
	lives += 1
	
	# Update HUD
	get_tree().call_group("hud", "set_lives", lives)
	
	# Play 1-up sound
	get_tree().call_group("audio_manager", "play_sound", SOUND_ONE_UP)
	
	print("[Player] Extra life! Lives: %d" % lives)


func collect_ammo(amount: int, is_special := false) -> void:
	## Collect ammo pickup
	if weapon_system:
		weapon_system.add_ammo(amount, is_special)
		get_tree().call_group("hud", "set_ammo", weapon_system.get_ammo())


func activate_halo() -> void:
	## Activate halo powerup (invincibility)
	## From docs/reference/items.md:
	## - Sets bit 0x01 of g_pPlayerState[0x17] (powerup_flags)
	## - Creates halo ring entity following player
	## - Provides one-hit protection
	
	powerup_flags |= 0x01  # Set halo bit
	
	# Play activation sound
	get_tree().call_group("audio_manager", "play_sound", SOUND_HALO_ACTIVATE)
	
	# Visual indicator (simplified - full implementation would create halo entity)
	modulate = Color(1.0, 1.0, 0.7)  # Golden glow
	
	print("[Player] Halo activated!")


func _handle_attack() -> void:
	## Handle attack input
	if Input.is_action_pressed("attack"):
		if weapon_system and weapon_system.can_fire():
			var fire_direction = Vector2(facing_direction, 0)
			weapon_system.fire_bullet(global_position, fire_direction)
	
	# Special attack (8-way)
	if Input.is_action_just_pressed("special_attack"):
		if weapon_system:
			weapon_system.fire_8_way(global_position)

