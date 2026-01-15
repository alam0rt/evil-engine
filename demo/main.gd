extends Node
## Main Entry Point - Skullmonkeys Complete Game
##
## This is the main() entry point for the complete game.
## Flow:
## 1. Show menu system
## 2. Player selects level or enters password
## 3. Load and play selected level
## 4. Return to menu on completion/death

# Preload systems
const MenuSystem = preload("res://addons/blb_importer/menu/menu_system.gd")
const GameManager = preload("res://addons/blb_importer/gameplay/game_manager.gd")
const AudioManager = preload("res://addons/blb_importer/audio/audio_manager.gd")
const GameHUD = preload("res://addons/blb_importer/gameplay/game_hud.gd")

# System nodes
var menu_system: Control = null
var game_manager: Node = null
var audio_manager: Node = null
var hud: CanvasLayer = null

# Game state
var current_level_path := ""
var level_progression := []  # List of levels in order


func _ready() -> void:
	print("=" * 60)
	print("SKULLMONKEYS - Complete Godot Port")
	print("=" * 60)
	print()
	
	# Initialize systems
	_init_audio_system()
	_init_game_manager()
	_init_hud()
	_init_menu_system()
	
	# Setup level progression
	_setup_level_list()
	
	# Show menu
	_show_menu()
	
	print("[Main] Game initialized - showing main menu")


func _init_audio_system() -> void:
	"""Initialize audio manager"""
	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	print("✓ Audio System initialized")


func _init_game_manager() -> void:
	"""Initialize game manager"""
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)
	
	# Connect signals
	game_manager.player_died.connect(_on_player_died)
	game_manager.game_over.connect(_on_game_over)
	
	print("✓ Game Manager initialized")


func _init_hud() -> void:
	"""Initialize HUD"""
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 100  # Above everything
	
	# Create HUD UI
	var margin = MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	
	# Lives
	var lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "Lives: 5"
	lives_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(lives_label)
	
	# Score
	var clayballs_label = Label.new()
	clayballs_label.name = "ClayballsLabel"
	clayballs_label.text = "Clayballs: 0"
	clayballs_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(clayballs_label)
	
	# Ammo
	var ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "Ammo: 0"
	ammo_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(ammo_label)
	
	margin.add_child(hbox)
	hud.add_child(margin)
	
	# Add HUD script
	hud.set_script(load("res://addons/blb_importer/gameplay/game_hud.gd"))
	
	add_child(hud)
	hud.visible = false  # Hidden until game starts
	
	print("✓ HUD initialized")


func _init_menu_system() -> void:
	"""Initialize menu system"""
	menu_system = Control.new()
	menu_system.name = "MenuSystem"
	menu_system.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_system.set_script(MenuSystem)
	
	# Create menu UI structure
	_create_menu_ui()
	
	add_child(menu_system)
	
	# Connect signals
	menu_system.start_game.connect(_on_start_game)
	menu_system.load_level.connect(_on_load_level_from_password)
	menu_system.quit_game.connect(_on_quit_game)
	
	print("✓ Menu System initialized")


func _create_menu_ui() -> void:
	"""Create menu UI elements"""
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.1, 0.1, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_system.add_child(bg)
	
	# Main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.anchor_left = 0.5
	main_container.anchor_top = 0.5
	main_container.anchor_right = 0.5
	main_container.anchor_bottom = 0.5
	main_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	main_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	main_container.add_theme_constant_override("separation", 20)
	menu_system.add_child(main_container)
	
	# Title
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "SKULLMONKEYS"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	main_container.add_child(spacer)
	
	# Menu container
	var menu_container = VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.add_theme_constant_override("separation", 10)
	main_container.add_child(menu_container)
	
	# Password container (hidden by default)
	var password_container = Control.new()
	password_container.name = "PasswordContainer"
	password_container.visible = false
	menu_system.add_child(password_container)
	
	# Options container (hidden by default)
	var options_container = Control.new()
	options_container.name = "OptionsContainer"
	options_container.visible = false
	menu_system.add_child(options_container)
	
	# Load game container (hidden by default)
	var load_game_container = Control.new()
	load_game_container.name = "LoadGameContainer"
	load_game_container.visible = false
	menu_system.add_child(load_game_container)


func _setup_level_list() -> void:
	"""Setup list of available levels"""
	# Check for extracted levels
	var levels_dir = "res://extracted/"
	
	if DirAccess.dir_exists_absolute(levels_dir):
		var dir = DirAccess.open(levels_dir)
		if dir:
			dir.list_dir_begin()
			var level_name = dir.get_next()
			
			while level_name != "":
				if dir.current_is_dir() and not level_name.begins_with("."):
					# Look for stage 0 scene
					var stage_path = levels_dir + level_name + "/" + level_name.to_lower() + "_stage0.tscn"
					if FileAccess.file_exists(stage_path):
						level_progression.append({
							"name": level_name,
							"path": stage_path
						})
				
				level_name = dir.get_next()
			
			dir.list_dir_end()
	
	print("[Main] Found %d levels" % level_progression.size())
	for level in level_progression:
		print("  - %s: %s" % [level["name"], level["path"]])


func _show_menu() -> void:
	"""Show main menu"""
	if menu_system:
		menu_system.visible = true
		menu_system.show_menu()
	
	if hud:
		hud.visible = false
	
	# Stop any music
	if audio_manager:
		audio_manager.stop_music()


func _hide_menu() -> void:
	"""Hide menu and show game"""
	if menu_system:
		menu_system.visible = false
	
	if hud:
		hud.visible = true


func _on_start_game() -> void:
	"""Start game from beginning"""
	print("[Main] Starting game")
	
	# Play menu select sound
	if audio_manager:
		audio_manager.play_menu_select()
	
	# Load first level
	if level_progression.size() > 0:
		_load_level(level_progression[0]["path"])
	else:
		push_error("[Main] No levels found! Please import a BLB file.")
		push_error("Place GAME.BLB in your project and it will auto-import.")


func _on_load_level_from_password(level_name: String) -> void:
	"""Load level from password entry"""
	print("[Main] Loading level from password: ", level_name)
	
	# Find level in progression
	for level in level_progression:
		if level["name"] == level_name:
			_load_level(level["path"])
			return
	
	# Try direct path
	var level_path = "res://extracted/%s/%s_stage0.tscn" % [level_name, level_name.to_lower()]
	if FileAccess.file_exists(level_path):
		_load_level(level_path)
	else:
		push_warning("[Main] Level not found: ", level_name)


func _load_level(level_path: String) -> void:
	"""Load and start a level"""
	print("[Main] Loading level: ", level_path)
	
	_hide_menu()
	current_level_path = level_path
	
	# Load through game manager
	if game_manager:
		game_manager.load_level(level_path)


func _on_player_died() -> void:
	"""Handle player death"""
	print("[Main] Player died")
	
	# Play death sound
	if audio_manager:
		audio_manager.play_sound(0x5860c640)  # Generic death sound


func _on_game_over() -> void:
	"""Handle game over"""
	print("[Main] Game over - returning to menu")
	
	# Show menu after delay
	await get_tree().create_timer(3.0).timeout
	_show_menu()


func _on_quit_game() -> void:
	"""Quit to desktop"""
	print("[Main] Quitting game")
	get_tree().quit()


func _input(event: InputEvent) -> void:
	"""Handle global input"""
	# ESC to toggle menu (when in game)
	if event.is_action_pressed("ui_cancel"):
		if menu_system and not menu_system.visible:
			# Show menu (pause game)
			_show_menu()
			get_tree().paused = true
			
			if audio_manager:
				audio_manager.play_pause()
		elif menu_system and menu_system.visible and game_manager.current_level:
			# Resume game
			_hide_menu()
			get_tree().paused = false

