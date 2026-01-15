extends Node
## Complete Game Demo - Shows full gameplay system in action
##
## This demo creates a playable game from an imported BLB level.
## It demonstrates:
## - Automatic level loading
## - Player spawning and controls
## - Entity conversion to gameplay objects
## - HUD display
## - Score tracking
## - Checkpoint system

# Preload gameplay components
const GameManager = preload("res://addons/blb_importer/gameplay/game_manager.gd")
const GameHUD = preload("res://addons/blb_importer/gameplay/game_hud.gd")
const Collectible = preload("res://addons/blb_importer/gameplay/collectible.gd")
const EnemyBase = preload("res://addons/blb_importer/gameplay/enemy_base.gd")
const PlayerCharacter = preload("res://addons/blb_importer/gameplay/player_character.gd")

@export_file("*.tscn") var level_to_load := "res://extracted/SCIE/scie_stage0.tscn"
@export var auto_convert_entities := true

var game_manager: Node = null
var hud: CanvasLayer = null


func _ready() -> void:
	print("=== Complete Game Demo ===")
	print("Starting playable Skullmonkeys port")
	
	# Create game manager
	_setup_game_manager()
	
	# Create HUD
	_setup_hud()
	
	# Load level
	if level_to_load and FileAccess.file_exists(level_to_load):
		print("Loading level: ", level_to_load)
		game_manager.load_level(level_to_load)
		
		# Convert entities if enabled
		if auto_convert_entities:
			await get_tree().process_frame  # Wait for level to be added
			_convert_entities_to_gameplay()
	else:
		push_warning("Level not found: ", level_to_load)
		push_warning("Please import a BLB file first or set level_to_load path")


func _setup_game_manager() -> void:
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)
	
	# Connect signals
	game_manager.level_loaded.connect(_on_level_loaded)
	game_manager.player_spawned.connect(_on_player_spawned)
	game_manager.player_died.connect(_on_player_died)
	
	print("✓ Game Manager created")


func _setup_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	
	# Create HUD container
	var margin = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	
	# Create HUD content
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	
	# Lives label
	var lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "Lives: 5"
	lives_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(lives_label)
	
	# Clayballs label
	var clayballs_label = Label.new()
	clayballs_label.name = "ClayballsLabel"
	clayballs_label.text = "Clayballs: 0"
	clayballs_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(clayballs_label)
	
	# Ammo label
	var ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "Ammo: 0"
	ammo_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(ammo_label)
	
	margin.add_child(hbox)
	hud.add_child(margin)
	
	# Add HUD script
	var hud_script = GameHUD.new()
	hud.set_script(load("res://addons/blb_importer/gameplay/game_hud.gd"))
	
	add_child(hud)
	print("✓ HUD created")


func _convert_entities_to_gameplay() -> void:
	## Convert imported BLB entities to gameplay objects
	print("\n=== Converting Entities to Gameplay ===")
	
	var converted_count := 0
	var collectibles_count := 0
	var enemies_count := 0
	
	# Convert collectibles
	for entity in get_tree().get_nodes_in_group("collectibles"):
		if entity.has_meta("gameplay_type"):
			var gameplay_type = entity.get_meta("gameplay_type")
			
			if gameplay_type == "collectible":
				var collectible = _create_collectible(entity)
				if collectible:
					collectibles_count += 1
					converted_count += 1
	
	# Convert enemies
	for entity in get_tree().get_nodes_in_group("enemies"):
		if entity.has_meta("gameplay_type"):
			var gameplay_type = entity.get_meta("gameplay_type")
			
			if gameplay_type == "enemy":
				var enemy = _create_enemy(entity)
				if enemy:
					enemies_count += 1
					converted_count += 1
	
	print("Converted %d entities:" % converted_count)
	print("  - %d collectibles" % collectibles_count)
	print("  - %d enemies" % enemies_count)
	print("=== Conversion Complete ===\n")


func _create_collectible(entity: Node) -> Node:
	## Create a Collectible Area2D from entity metadata
	var collectible = Area2D.new()
	collectible.set_script(Collectible)
	collectible.name = entity.name + "_Gameplay"
	collectible.global_position = entity.global_position
	
	# Set collectible type from metadata
	if entity.has_meta("collectible_type"):
		collectible.collectible_type = entity.get_meta("collectible_type")
	
	# Add collision shape (simple circle for now)
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	collectible.add_child(collision)
	
	# Copy sprite if entity has one
	for child in entity.get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			var sprite_copy = child.duplicate()
			collectible.add_child(sprite_copy)
			break
	
	# Add to scene
	if entity.get_parent():
		entity.get_parent().add_child(collectible)
	
	# Remove original entity
	entity.queue_free()
	
	return collectible


func _create_enemy(entity: Node) -> Node:
	## Create an Enemy CharacterBody2D from entity metadata
	var enemy = CharacterBody2D.new()
	enemy.set_script(EnemyBase)
	enemy.name = entity.name + "_Gameplay"
	enemy.global_position = entity.global_position
	
	# Set AI pattern from metadata
	if entity.has_meta("enemy_ai"):
		var ai_pattern_name = entity.get_meta("enemy_ai")
		match ai_pattern_name:
			"patrol":
				enemy.ai_pattern = EnemyBase.AIPattern.PATROL
			"chase":
				enemy.ai_pattern = EnemyBase.AIPattern.CHASE
			"ranged":
				enemy.ai_pattern = EnemyBase.AIPattern.RANGED
			"flying":
				enemy.ai_pattern = EnemyBase.AIPattern.FLYING
			"stationary":
				enemy.ai_pattern = EnemyBase.AIPattern.STATIONARY
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	enemy.add_child(collision)
	
	# Copy sprite if entity has one
	for child in entity.get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			var sprite_copy = child.duplicate()
			sprite_copy.name = "Sprite"
			enemy.add_child(sprite_copy)
			break
	
	# Add to scene
	if entity.get_parent():
		entity.get_parent().add_child(enemy)
	
	# Remove original entity
	entity.queue_free()
	
	return enemy


func _on_level_loaded(level_name: String) -> void:
	print("✓ Level loaded: ", level_name)


func _on_player_spawned(player: Node) -> void:
	print("✓ Player spawned at: ", player.global_position)


func _on_player_died() -> void:
	print("✗ Player died!")


func _input(event: InputEvent) -> void:
	# Debug controls
	if event.is_action_pressed("ui_cancel"):
		# Reload level
		if game_manager:
			game_manager.load_level(level_to_load)
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# Quick restart
				get_tree().reload_current_scene()
			KEY_F1:
				# Toggle debug info
				print("\n=== Debug Info ===")
				print("Collectibles: ", get_tree().get_nodes_in_group("collectibles").size())
				print("Enemies: ", get_tree().get_nodes_in_group("enemies").size())
				print("Player nodes: ", get_tree().get_nodes_in_group("player").size())
				print("==================\n")

