extends Node
class_name GameManager
## Game Manager - Handles overall game state and level management
##
## Based on docs/systems/game-loop.md and docs/systems/level-loading.md
## Coordinates:
## - Level loading/unloading
## - Player spawning/respawning
## - Checkpoint system
## - Score/collectibles tracking
## - HUD updates

signal level_loaded(level_name: String)
signal player_spawned(player: Node2D)
signal player_died()
signal checkpoint_reached(checkpoint_id: int)
signal game_over()

# Game state
var current_level: Node2D = null
var player: Node2D = null
var spawn_point := Vector2.ZERO
var last_checkpoint := Vector2.ZERO
var checkpoint_id := 0

# Score tracking
var clayballs_collected := 0
var total_clayballs := 0
var lives_remaining := 5
var ammo_count := 0

# Level progression
var current_level_index := 0
var current_stage_index := 0


func _ready() -> void:
	add_to_group("game_manager")
	
	# Set up input actions if not already defined
	_setup_input_actions()


func _setup_input_actions() -> void:
	## Ensure input actions are defined
	var actions := ["move_left", "move_right", "jump", "run", "attack"]
	
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	
	# Add default keyboard mappings
	if not InputMap.has_action("move_left"):
		_add_key_to_action("move_left", KEY_LEFT)
		_add_key_to_action("move_left", KEY_A)
	
	if not InputMap.has_action("move_right"):
		_add_key_to_action("move_right", KEY_RIGHT)
		_add_key_to_action("move_right", KEY_D)
	
	if not InputMap.has_action("jump"):
		_add_key_to_action("jump", KEY_SPACE)
		_add_key_to_action("jump", KEY_W)
		_add_key_to_action("jump", KEY_UP)
	
	if not InputMap.has_action("run"):
		_add_key_to_action("run", KEY_SHIFT)
	
	if not InputMap.has_action("attack"):
		_add_key_to_action("attack", KEY_CTRL)
		_add_key_to_action("attack", KEY_X)


func _add_key_to_action(action: String, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	InputMap.action_add_event(action, event)


func load_level(level_scene_path: String) -> void:
	## Load a BLB level scene
	# Unload current level
	if current_level:
		current_level.queue_free()
		current_level = null
	
	# Load new level
	var level_scene := load(level_scene_path)
	if not level_scene:
		push_error("Failed to load level: %s" % level_scene_path)
		return
	
	current_level = level_scene.instantiate()
	add_child(current_level)
	
	# Find spawn point
	_find_spawn_point()
	
	# Count collectibles
	_count_collectibles()
	
	# Spawn player
	spawn_player()
	
	# Setup camera
	_setup_camera()
	
	level_loaded.emit(level_scene_path)


func _find_spawn_point() -> void:
	## Find spawn point marker in level
	var spawn_markers := get_tree().get_nodes_in_group("spawn_point")
	if spawn_markers.size() > 0:
		spawn_point = spawn_markers[0].global_position
	else:
		# Look for SpawnPoint node
		var spawn_node := current_level.find_child("SpawnPoint", true, false)
		if spawn_node:
			spawn_point = spawn_node.global_position
		else:
			# Default spawn
			spawn_point = Vector2(100, 100)
	
	last_checkpoint = spawn_point


func _count_collectibles() -> void:
	## Count total clayballs in level (entity type 2)
	## From docs/systems/enemies/type-002-clayball.md:
	## "Count: 5,727 instances (most common entity!)"
	## Average ~220 per level
	
	var collectibles := get_tree().get_nodes_in_group("collectibles")
	total_clayballs = 0
	
	for collectible in collectibles:
		# Check if it's a clayball (entity type 2)
		if collectible.has("entity_type") and collectible.entity_type == 2:
			total_clayballs += 1
		# Also check metadata
		elif collectible.has_meta("entity_type") and collectible.get_meta("entity_type") == 2:
			total_clayballs += 1
		# Check collectible_type for converted entities
		elif collectible.has("collectible_type") and collectible.collectible_type == 0:  # Collectible.Type.CLAYBALL
			total_clayballs += 1
	
	# Update HUD
	get_tree().call_group("hud", "set_total_clayballs", total_clayballs)
	
	print("[GameManager] Level has %d clayballs" % total_clayballs)


func spawn_player() -> void:
	## Spawn player at current spawn point
	## Detects level flags to spawn correct player type
	## From docs/systems/player/player-soar-glide.md and SpawnPlayerAndEntities @ 0x8007df38
	
	# Remove old player
	if player:
		player.queue_free()
	
	# Detect level type from flags (checked in priority order from docs)
	var level_flags := _get_level_flags()
	player = _create_player_for_level_type(level_flags)
	
	if not player:
		push_error("[GameManager] Failed to create player!")
		return
	
	# Position at spawn
	player.global_position = spawn_point
	
	# Add to scene
	if current_level:
		current_level.add_child(player)
	else:
		add_child(player)
	
	# Initialize player state (from docs/systems/player/player-system.md)
	if player.has("lives"):
		player.lives = lives_remaining
	if player.has("orb_count"):
		player.orb_count = 0  # Clayballs reset per level or persist?
	
	player_spawned.emit(player)
	
	print("[GameManager] Spawned player type for flags 0x%04x" % level_flags)


func _get_level_flags() -> int:
	## Get level flags from current level's BLBStageRoot
	if not current_level:
		return 0
	
	# Find BLBStageRoot (should be the root itself or find it)
	var stage_root = current_level
	if stage_root.has("level_flags"):
		return stage_root.level_flags
	
	# Search children for BLBStageRoot
	for child in current_level.get_children():
		if child.has("level_flags"):
			return child.level_flags
	
	return 0


func _create_player_for_level_type(flags: int) -> Node2D:
	## Create correct player type based on level flags
	## From docs/systems/player/player-soar-glide.md lines 142-171
	## Priority order (must check in this exact order):
	
	# 1. FINN mode (0x400) - Swimming/tank controls
	if flags & 0x400:
		print("[GameManager] Creating FINN player (swimming mode)")
		return _create_finn_player()
	
	# 2. Menu mode (0x200) - Skip (shouldn't spawn player in menu)
	if flags & 0x200:
		print("[GameManager] Menu level - no player spawn")
		return null
	
	# 3. Boss mode (0x2000) - Normal player with boss flag
	if flags & 0x2000:
		print("[GameManager] Creating player for boss level")
		return _create_normal_player()  # Use normal, boss is separate entity
	
	# 4. RUNN mode (0x100) - Auto-scroller
	if flags & 0x100:
		print("[GameManager] Creating RUNN player (auto-scroller)")
		return _create_runn_player()
	
	# 5. SOAR mode (0x10) - Flying
	if flags & 0x10:
		print("[GameManager] Creating SOAR player (flying)")
		return _create_soar_player()
	
	# 6. GLIDE mode (0x04) - Gliding
	if flags & 0x04:
		print("[GameManager] Creating GLIDE player (gliding)")
		return _create_glide_player()
	
	# 7. Normal mode (default) - Standard platforming
	print("[GameManager] Creating normal player")
	return _create_normal_player()


func _create_normal_player() -> Node2D:
	## Create standard platformer player
	var player_scene := load("res://addons/blb_importer/gameplay/player_character.tscn")
	if player_scene:
		return player_scene.instantiate()
	return _create_player_programmatic()


func _create_finn_player() -> Node2D:
	## Create FINN mode player (swimming/tank controls)
	var PlayerFinn = load("res://addons/blb_importer/gameplay/player_finn.gd")
	var finn = CharacterBody2D.new()
	finn.set_script(PlayerFinn)
	finn.name = "PlayerFinn"
	
	# Add sprite
	var sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	finn.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 32)  # Wider for boat
	collision.shape = shape
	collision.name = "CollisionShape"
	finn.add_child(collision)
	
	return finn


func _create_runn_player() -> Node2D:
	## Create RUNN mode player (auto-scroller)
	var PlayerRunn = load("res://addons/blb_importer/gameplay/player_runn.gd")
	var runn = CharacterBody2D.new()
	runn.set_script(PlayerRunn)
	runn.name = "PlayerRunn"
	
	# Add sprite
	var sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	runn.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	collision.name = "CollisionShape"
	runn.add_child(collision)
	
	return runn


func _create_soar_player() -> Node2D:
	## Create SOAR mode player (flying)
	var PlayerSoar = load("res://addons/blb_importer/gameplay/player_soar.gd")
	var soar = CharacterBody2D.new()
	soar.set_script(PlayerSoar)
	soar.name = "PlayerSoar"
	
	# Add sprite
	var sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	soar.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	collision.name = "CollisionShape"
	soar.add_child(collision)
	
	return soar


func _create_glide_player() -> Node2D:
	## Create GLIDE mode player (gliding)
	var PlayerGlide = load("res://addons/blb_importer/gameplay/player_glide.gd")
	var glide = CharacterBody2D.new()
	glide.set_script(PlayerGlide)
	glide.name = "PlayerGlide"
	
	# Add sprite
	var sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	glide.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	collision.name = "CollisionShape"
	glide.add_child(collision)
	
	return glide


func _create_player_programmatic() -> Node2D:
	## Create player character programmatically (fallback)
	var player_script := load("res://addons/blb_importer/gameplay/player_character.gd")
	var new_player := CharacterBody2D.new()
	new_player.set_script(player_script)
	
	# Add sprite
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	new_player.add_child(sprite)
	
	# Add collision shape
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	collision.name = "CollisionShape"
	new_player.add_child(collision)
	
	return new_player


func _setup_camera() -> void:
	## Setup camera to follow player
	if not player:
		return
	
	# Check if player already has camera
	if player.find_child("Camera2D"):
		return
	
	# Add camera to player
	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.enabled = true
	
	# Camera limits based on level bounds
	if current_level and current_level.has("level_width") and current_level.has("level_height"):
		var level_width: int = current_level.level_width
		var level_height: int = current_level.level_height
		
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = level_width * 16  # Tile size
		camera.limit_bottom = level_height * 16
	
	player.add_child(camera)


func on_player_death() -> void:
	## Handle player death
	player_died.emit()
	
	lives_remaining -= 1
	
	if lives_remaining <= 0:
		_game_over()
	else:
		# Respawn after delay
		await get_tree().create_timer(2.0).timeout
		respawn_player()


func respawn_player() -> void:
	## Respawn player at last checkpoint
	if player and player.has_method("respawn"):
		player.respawn(last_checkpoint)
	else:
		spawn_player()


func save_checkpoint(position: Vector2, id: int) -> void:
	## Save checkpoint position
	last_checkpoint = position
	checkpoint_id = id
	checkpoint_reached.emit(id)
	
	print("Checkpoint saved at ", position)


func _game_over() -> void:
	## Handle game over
	game_over.emit()
	
	# Show game over screen
	# Reset game state
	await get_tree().create_timer(3.0).timeout
	
	# Reload level
	lives_remaining = 5
	clayballs_collected = 0
	if current_level:
		load_level(current_level.scene_file_path)


# HUD update functions (called by player/collectibles)
func add_clayballs(amount: int) -> void:
	clayballs_collected += amount
	get_tree().call_group("hud", "set_clayballs", clayballs_collected)


func add_ammo(amount: int) -> void:
	ammo_count += amount
	get_tree().call_group("hud", "set_ammo", ammo_count)


func set_lives(lives: int) -> void:
	lives_remaining = lives
	get_tree().call_group("hud", "set_lives", lives_remaining)

