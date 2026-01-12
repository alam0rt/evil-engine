extends Node2D
class_name GameRunner

## PSX-Authentic Game Runner for Skullmonkeys
##
## Implements the game loop based on Ghidra decompilation of main() (0x800828b0):
##
## GAME LOOP (per frame):
## 1. Update input state (UpdateInputState)
## 2. Execute mode callback (level gameplay, menu, etc)
## 3. EntityTickLoop - Update all active entities
## 4. RenderEntities - Draw entity sprites
## 5. Render tile layers
## 6. VSync timing
##
## LEVEL INITIALIZATION (InitializeAndLoadLevel @ 0x8007d1d0):
## 1. Load tile data to VRAM
## 2. InitPlayerSpawnPosition
## 3. LoadBGColorFromTileHeader
## 4. LoadEntitiesFromAsset501
## 5. InitLayersAndTileState

# PSX constants
const PSX_WIDTH: int = 320
const PSX_HEIGHT: int = 240
const FIXED_POINT_SCALE: float = 65536.0  # 16.16 fixed point
const TILE_SIZE: int = 16

# Exports
@export_file("*.BLB") var blb_path: String = ""
@export var level_id: String = "CLOU"  # 4-letter level ID from BLB header
@export var level_index: int = -1  # Auto-resolved from level_id, or override manually
@export var stage_index: int = 1
@export var scale_factor: int = 2

# Game state (mirrors PSX GameState structure)
var game_state: Dictionary = {
	# Camera position (GameState+0x48/0x4A = level dimensions)
	"camera_x": 0,
	"camera_y": 0,
	# Player spawn (from TileHeader)
	"spawn_x": 0,
	"spawn_y": 0,
	# Level dimensions in pixels (width*16, height*16)
	"level_width": 0,
	"level_height": 0,
	# Background color
	"bg_color": Color.BLACK,
	# Level metadata
	"level_name": "",
	"level_id": "",
}

# Input state (mirrors g_pPlayer1Input)
var input_state: Dictionary = {
	"pad_current": 0,      # Current frame buttons
	"pad_previous": 0,     # Previous frame buttons
	"pad_pressed": 0,      # Just pressed this frame
	"pad_released": 0,     # Just released this frame
}

# PSX button mappings
enum PSXButton {
	SELECT = 0x0001,
	L3 = 0x0002,
	R3 = 0x0004,
	START = 0x0008,
	UP = 0x0010,
	RIGHT = 0x0020,
	DOWN = 0x0040,
	LEFT = 0x0080,
	L2 = 0x0100,
	R2 = 0x0200,
	L1 = 0x0400,
	R1 = 0x0800,
	TRIANGLE = 0x1000,
	CIRCLE = 0x2000,
	CROSS = 0x4000,
	SQUARE = 0x8000,
}

# Active entities (linked list in original, array here)
var active_entities: Array[Dictionary] = []

# Layer data
var layers: Array[Dictionary] = []

# Player state (mirrors GameState+0x116/0x118)
var player: Dictionary = {
	"x": 0.0,           # Pixel position (GameState+0x116)
	"y": 0.0,           # Pixel position (GameState+0x118)
	"vel_x": 0.0,       # Velocity
	"vel_y": 0.0,
	"on_ground": false,
	"width": 16,        # Collision box
	"height": 32,
}
var player_node: ColorRect  # Visual representation

# Rendering
var viewport: SubViewport
var viewport_sprite: Sprite2D
var entity_container: Node2D
var layer_container: Node2D
var player_container: Node2D

# BLB access - prefer C99 GDExtension over GDScript reader
var blb_archive: BLBArchive = null  # C99 GDExtension (fast, for level lookup/tiles/layers)
var blb_reader: Object = null       # GDScript fallback (for stage_data dict)

# Frame counter
var frame_count: int = 0

# Debug
var debug_label: Label
@export var show_debug: bool = true


func _ready() -> void:
	print("[GameRunner] === PSX Game Runner Starting ===")
	print("[GameRunner] Based on main() @ 0x800828b0")
	print("")
	
	# Parse CLI arguments (--level NAME --stage N)
	_parse_cli_arguments()
	
	# Initialize graphics (InitGraphicsSystem @ 0x80013268)
	_init_graphics_system()
	
	# Initialize game state (InitGameState @ 0x8007cd34)
	_init_game_state()
	
	# Load level (InitializeAndLoadLevel @ 0x8007d1d0)
	if blb_path != "" or _find_default_blb():
		_initialize_and_load_level()


func _parse_cli_arguments() -> void:
	## Parse command line arguments: --level NAME --stage N
	var args = OS.get_cmdline_user_args()
	print("[GameRunner] CLI args: %s" % [args])
	var i := 0
	while i < args.size():
		var arg = args[i]
		if arg == "--level" and i + 1 < args.size():
			level_id = args[i + 1].to_upper()
			print("[GameRunner] CLI: level_id=%s" % level_id)
			i += 2
		elif arg == "--stage" and i + 1 < args.size():
			stage_index = int(args[i + 1])
			print("[GameRunner] CLI: stage=%d" % stage_index)
			i += 2
		else:
			i += 1


func _find_default_blb() -> bool:
	var paths = [
		"res://assets/GAME.BLB",
		"/home/sam/projects/btm/disks/blb/GAME.BLB",
	]
	for path in paths:
		if FileAccess.file_exists(path):
			blb_path = path
			return true
	push_warning("[GameRunner] No BLB file found")
	return false


func _init_graphics_system() -> void:
	## Mirrors InitGraphicsSystem (0x80013268)
	## Sets up double-buffered display at 320x240
	
	print("[GameRunner] InitGraphicsSystem...")
	
	# Set window size
	get_window().size = Vector2i(PSX_WIDTH * scale_factor, PSX_HEIGHT * scale_factor)
	get_window().title = "Skullmonkeys - Game Runner (PSX 320x240)"
	
	# Create SubViewport for PSX resolution
	viewport = SubViewport.new()
	viewport.size = Vector2i(PSX_WIDTH, PSX_HEIGHT)
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	
	# Display viewport contents
	viewport_sprite = Sprite2D.new()
	viewport_sprite.texture = viewport.get_texture()
	viewport_sprite.centered = false
	viewport_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(viewport_sprite)
	
	# Create layer container (behind entities)
	layer_container = Node2D.new()
	layer_container.name = "Layers"
	viewport.add_child(layer_container)
	
	# Create entity container (in front of layers)
	entity_container = Node2D.new()
	entity_container.name = "Entities"
	entity_container.z_index = 100
	viewport.add_child(entity_container)
	
	# Create player container (z=10000 like original)
	player_container = Node2D.new()
	player_container.name = "Player"
	player_container.z_index = 200  # In front of entities
	viewport.add_child(player_container)
	
	# Create player visual (simple colored box)
	player_node = ColorRect.new()
	player_node.name = "PlayerSprite"
	player_node.color = Color(0.2, 0.6, 1.0, 0.9)  # Blue
	player_node.size = Vector2(player.width, player.height)
	player_container.add_child(player_node)
	
	# Debug HUD
	_create_debug_hud()
	
	print("[GameRunner] Graphics initialized: %dx%d @ %dx scale" % [PSX_WIDTH, PSX_HEIGHT, scale_factor])


func _init_game_state() -> void:
	## Mirrors InitGameState (0x8007cd34)
	## Initializes player state and game variables
	
	print("[GameRunner] InitGameState...")
	
	# Clear input state
	input_state.pad_current = 0
	input_state.pad_previous = 0
	input_state.pad_pressed = 0
	input_state.pad_released = 0
	
	# Reset camera
	game_state.camera_x = 0
	game_state.camera_y = 0


func _initialize_and_load_level() -> void:
	## Mirrors InitializeAndLoadLevel (0x8007d1d0)
	## Main level loading sequence
	
	print("[GameRunner] InitializeAndLoadLevel...")
	
	# Convert res:// path to filesystem path for C99 library
	var fs_path = blb_path
	if blb_path.begins_with("res://"):
		fs_path = ProjectSettings.globalize_path(blb_path)
	
	# Open BLB with C99 GDExtension (keep as member for later use)
	if blb_archive == null:
		blb_archive = BLBArchive.new()
	if not blb_archive.open(fs_path):
		push_error("[GameRunner] Failed to open BLB with C99 library: %s" % fs_path)
		return
	
	# Resolve level_id to level_index using C99 library
	print("[GameRunner] DEBUG: level_index=%d, level_id='%s'" % [level_index, level_id])
	if level_index < 0 and level_id != "":
		var found_idx = blb_archive.find_level_by_id(level_id)
		print("[GameRunner] DEBUG: find_level_by_id('%s') returned %d" % [level_id, found_idx])
		level_index = found_idx
		if level_index < 0:
			push_error("[GameRunner] Unknown level ID: %s" % level_id)
			return
	
	# Get actual level ID and name from BLB header
	var actual_level_id = blb_archive.get_level_id(level_index)
	var actual_level_name = blb_archive.get_level_name(level_index)
	print("[GameRunner] Loading: %s (%s) stage %d (index %d)" % [
		actual_level_id, actual_level_name, stage_index, level_index
	])
	
	# Load BLB and stage data using BLBReader (still needed for tiles/sprites)
	var BLBReader = load("res://addons/blb_importer/blb_reader.gd")
	if BLBReader == null:
		push_error("[GameRunner] Failed to load BLBReader")
		return
	
	blb_reader = BLBReader.new()
	if not blb_reader.open(blb_path):
		push_error("[GameRunner] Failed to open BLB: %s" % blb_path)
		return
	
	var stage_data = blb_reader.load_stage(level_index, stage_index)
	if stage_data.is_empty():
		push_error("[GameRunner] Failed to load stage data")
		return
	
	# Also load in C99 library for fast tile/layer access
	if not blb_archive.load_level(level_index, stage_index):
		push_warning("[GameRunner] C99 load_level failed, using GDScript fallback")
	
	# LoadTileDataToVRAM (0x80025240) - handled by BLBReader
	print("[GameRunner] LoadTileDataToVRAM... (handled by importer)")
	
	# InitPlayerSpawnPosition (0x80024720)
	_init_player_spawn_position(stage_data)
	
	# LoadBGColorFromTileHeader
	_load_bg_color(stage_data)
	
	# LoadEntitiesFromAsset501
	_load_entities(stage_data)
	
	# InitLayersAndTileState (0x80024778)
	_init_layers_and_tile_state(stage_data)
	
	# Camera will follow player (set initial position based on player)
	var target_cam_x = player.x - PSX_WIDTH / 2.0
	var target_cam_y = player.y - PSX_HEIGHT / 2.0
	game_state.camera_x = clampf(target_cam_x, 0, max(0, game_state.level_width - PSX_WIDTH))
	game_state.camera_y = clampf(target_cam_y, 0, max(0, game_state.level_height - PSX_HEIGHT))
	
	print("[GameRunner] Level loaded: %s (%s)" % [game_state.level_name, game_state.level_id])
	print("[GameRunner] Size: %dx%d, Spawn: (%d, %d)" % [
		game_state.level_width, game_state.level_height,
		game_state.spawn_x, game_state.spawn_y
	])
	print("[GameRunner] Player: (%d, %d)" % [int(player.x), int(player.y)])
	print("[GameRunner] Entities: %d, Layers: %d" % [active_entities.size(), layers.size()])


func _init_player_spawn_position(stage_data: Dictionary) -> void:
	## Mirrors InitPlayerSpawnPosition (0x80024720)
	## Sets player position from TileHeader spawn coords:
	##   GameState+0x116 = spawn_x * 16 + 8  (center of tile)
	##   GameState+0x118 = spawn_y * 16 + 15 (bottom of tile)
	
	var tile_header = stage_data.get("tile_header", {})
	var spawn_tile_x = tile_header.get("spawn_x", 0)
	var spawn_tile_y = tile_header.get("spawn_y", 0)
	
	# Convert to pixel coords (PSX formula from Ghidra)
	game_state.spawn_x = spawn_tile_x * TILE_SIZE + 8   # Center of tile
	game_state.spawn_y = spawn_tile_y * TILE_SIZE + 15  # Bottom of tile
	game_state.level_width = tile_header.get("level_width", 20) * TILE_SIZE
	game_state.level_height = tile_header.get("level_height", 15) * TILE_SIZE
	game_state.level_name = stage_data.get("level_name", "UNKNOWN")
	game_state.level_id = stage_data.get("level_id", "????")
	
	# Initialize player at spawn
	player.x = float(game_state.spawn_x)
	player.y = float(game_state.spawn_y)
	player.vel_x = 0.0
	player.vel_y = 0.0
	
	print("[GameRunner] InitPlayerSpawnPosition: (%d, %d)" % [game_state.spawn_x, game_state.spawn_y])


func _load_bg_color(_stage_data: Dictionary) -> void:
	## Mirrors LoadBGColorFromTileHeader
	## Sets the viewport clear color (visible where no layers cover)
	## Uses C99 GDExtension for fast access
	
	if blb_archive != null:
		game_state.bg_color = blb_archive.get_background_color()
	else:
		# Fallback to GDScript parsing
		var tile_header = _stage_data.get("tile_header", {})
		var r = tile_header.get("bg_r", 0)
		var g = tile_header.get("bg_g", 0)
		var b = tile_header.get("bg_b", 0)
		game_state.bg_color = Color8(r, g, b)
	
	# Set clear color - this shows through where layers don't cover
	RenderingServer.set_default_clear_color(game_state.bg_color)
	
	# Also set SubViewport's clear color
	viewport.transparent_bg = false
	
	var r = int(game_state.bg_color.r8)
	var g = int(game_state.bg_color.g8)
	var b = int(game_state.bg_color.b8)
	print("[GameRunner] BG Color: RGB(%d, %d, %d)" % [r, g, b])


func _load_entities(stage_data: Dictionary) -> void:
	## Mirrors LoadEntitiesFromAsset501
	## Loads 24-byte entity structures from stage data
	
	var entity_list = stage_data.get("entities", [])
	active_entities.clear()
	
	for entity_def in entity_list:
		var entity = {
			# Position (from 24-byte structure)
			"x1": entity_def.get("x1", 0),
			"y1": entity_def.get("y1", 0),
			"x2": entity_def.get("x2", 0),
			"y2": entity_def.get("y2", 0),
			"x_center": entity_def.get("x_center", 0),
			"y_center": entity_def.get("y_center", 0),
			"entity_type": entity_def.get("entity_type", 0),
			"variant": entity_def.get("variant", 0),
			"layer": entity_def.get("layer", 0),
			# Runtime state
			"active": true,
			"visible": true,
			# Rendering
			"sprite": null,
		}
		active_entities.append(entity)
	
	print("[GameRunner] Loaded %d entities" % active_entities.size())


func _init_layers_and_tile_state(stage_data: Dictionary) -> void:
	## Mirrors InitLayersAndTileState (0x80024778)
	## Sets up layer rendering with proper parallax using StageSceneBuilder
	
	layers.clear()
	
	# Clear existing layer children
	for child in layer_container.get_children():
		child.queue_free()
	
	# Use StageSceneBuilder to create the stage scene
	var StageSceneBuilderClass = load("res://addons/blb_importer/stage_scene_builder.gd")
	if StageSceneBuilderClass == null:
		push_error("[GameRunner] Failed to load StageSceneBuilder")
		return
	
	var builder = StageSceneBuilderClass.new()
	var packed_scene = builder.build_scene(stage_data, blb_reader)
	
	if packed_scene == null:
		push_warning("[GameRunner] Failed to build stage scene")
		return
	
	# Instance the scene
	var stage_root = packed_scene.instantiate()
	
	# Extract TileLayers container and move to our layer_container
	var tile_layers = stage_root.get_node_or_null("TileLayers")
	if tile_layers:
		stage_root.remove_child(tile_layers)
		layer_container.add_child(tile_layers)
		
		# Get layer count from C99 library if available
		var c99_layer_count = 0
		if blb_archive != null:
			c99_layer_count = blb_archive.get_layer_count()
		
		print("[GameRunner] C99 layer_count: %d, tile_layers children: %d" % [c99_layer_count, tile_layers.get_child_count()])
		
		# Store layer metadata for parallax updates - prefer C99 GDExtension
		for i in range(tile_layers.get_child_count()):
			var layer_node = tile_layers.get_child(i)
			
			# Extract layer index from node name (e.g., "Layer_0")
			var layer_idx := i
			if layer_node.name.begins_with("Layer_"):
				layer_idx = int(layer_node.name.substr(6))
			
			# Get scroll factors from C99 library
			var scroll_x := 65536
			var scroll_y := 65536
			if blb_archive != null and layer_idx < c99_layer_count:
				var c99_layer_info = blb_archive.get_layer_info(layer_idx)
				scroll_x = c99_layer_info.get("scroll_x", 65536)
				scroll_y = c99_layer_info.get("scroll_y", 65536)
			
			var layer_info = {
				"index": layer_idx,
				"node": layer_node,
				"base_position": layer_node.position,
				"scroll_x": scroll_x,
				"scroll_y": scroll_y,
			}
			layers.append(layer_info)
			print("[GameRunner] Layer %d: base_pos=%s, scroll=%d,%d (%.3f,%.3f)" % [
				layer_idx, layer_info.base_position,
				layer_info.scroll_x, layer_info.scroll_y,
				float(layer_info.scroll_x) / 65536.0, float(layer_info.scroll_y) / 65536.0
			])
	
	# Don't extract the Background ColorRect from StageSceneBuilder -
	# we use the viewport clear color instead (set in _load_bg_color)
	
	# Clean up the temporary root
	stage_root.queue_free()
	
	print("[GameRunner] Initialized %d layers from StageSceneBuilder" % layers.size())


func _process(_delta: float) -> void:
	## Main game loop - mirrors main() game loop
	## Called every frame (~60fps, PSX was ~30fps PAL / ~60fps NTSC)
	
	frame_count += 1
	
	# 1. Update input state (UpdateInputState)
	_update_input_state()
	
	# 2. Mode callback (gameplay, menu, etc) - simplified for now
	_process_gameplay()
	
	# 3. EntityTickLoop (0x80020e1c)
	_entity_tick_loop()
	
	# 4. Update parallax / camera
	_update_parallax()
	
	# 5. RenderEntities (drawing happens via Godot scene tree)
	
	# 6. Update debug HUD
	if show_debug:
		_update_debug_hud()


func _update_input_state() -> void:
	## Mirrors UpdateInputState
	## Converts keyboard/gamepad to PSX button state
	
	input_state.pad_previous = input_state.pad_current
	input_state.pad_current = 0
	
	# Map keyboard to PSX buttons (arrows and WASD)
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_state.pad_current |= PSXButton.LEFT
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_state.pad_current |= PSXButton.RIGHT
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_state.pad_current |= PSXButton.UP
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_state.pad_current |= PSXButton.DOWN
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_SPACE):
		input_state.pad_current |= PSXButton.CROSS  # Jump
	if Input.is_key_pressed(KEY_X):
		input_state.pad_current |= PSXButton.SQUARE  # Attack
	if Input.is_key_pressed(KEY_C):
		input_state.pad_current |= PSXButton.CIRCLE
	if Input.is_key_pressed(KEY_ENTER):
		input_state.pad_current |= PSXButton.START
	if Input.is_key_pressed(KEY_SHIFT):
		input_state.pad_current |= PSXButton.SELECT
	
	# Calculate pressed/released
	input_state.pad_pressed = input_state.pad_current & ~input_state.pad_previous
	input_state.pad_released = input_state.pad_previous & ~input_state.pad_current


func _process_gameplay() -> void:
	## Player movement and camera follow
	## Camera centers on player (screen center = 160, 120)
	
	var move_speed = 2.5
	
	# Move player with d-pad/arrows
	if input_state.pad_current & PSXButton.LEFT:
		player.x -= move_speed
	if input_state.pad_current & PSXButton.RIGHT:
		player.x += move_speed
	if input_state.pad_current & PSXButton.UP:
		player.y -= move_speed
	if input_state.pad_current & PSXButton.DOWN:
		player.y += move_speed
	
	# Clamp player to level bounds
	player.x = clampf(player.x, player.width / 2.0, game_state.level_width - player.width / 2.0)
	player.y = clampf(player.y, player.height, game_state.level_height)
	
	# Camera follows player (center player on screen)
	# Screen center is at (160, 120) in PSX coords
	var target_cam_x = player.x - PSX_WIDTH / 2.0
	var target_cam_y = player.y - PSX_HEIGHT / 2.0
	
	# Clamp camera to level bounds
	game_state.camera_x = clampf(target_cam_x, 0, max(0, game_state.level_width - PSX_WIDTH))
	game_state.camera_y = clampf(target_cam_y, 0, max(0, game_state.level_height - PSX_HEIGHT))
	
	# Update player visual position (in viewport coords)
	var screen_x = player.x - game_state.camera_x - player.width / 2.0
	var screen_y = player.y - game_state.camera_y - player.height
	player_node.position = Vector2(screen_x, screen_y)


func _entity_tick_loop() -> void:
	## Mirrors EntityTickLoop (0x80020e1c)
	## Iterates active entity list and calls update functions
	
	for entity in active_entities:
		if not entity.active:
			continue
		
		# Entity update logic would go here
		# In the original, each entity has a function pointer for its update
		# For now, just check visibility based on camera
		var ex = entity.x_center
		var ey = entity.y_center
		var cx = game_state.camera_x
		var cy = game_state.camera_y
		
		# Simple visibility check (entity within viewport + margin)
		var margin = 64
		entity.visible = (
			ex >= cx - margin and ex < cx + PSX_WIDTH + margin and
			ey >= cy - margin and ey < cy + PSX_HEIGHT + margin
		)


func _update_parallax() -> void:
	## Update layer positions based on camera and scroll factors
	## Mirrors RenderTilemapSprites16x16 (0x8001713c) positioning
	##
	## PSX parallax formula (16.16 fixed point):
	## - scroll=0: Layer stays fixed to screen (background, doesn't move)
	## - scroll=65536 (1.0): Layer scrolls 1:1 with camera (foreground)
	## - scroll<65536: Layer scrolls slower than camera (distant parallax)
	##
	## In viewport space: layer_screen_pos = layer_world_pos - camera * scroll_factor
	
	for layer in layers:
		var layer_node = layer.get("node")
		if layer_node == null:
			continue
		
		var scroll_x = float(layer.scroll_x) / FIXED_POINT_SCALE
		var scroll_y = float(layer.scroll_y) / FIXED_POINT_SCALE
		var base_pos: Vector2 = layer.base_position
		
		# Calculate screen position: layer moves relative to camera by scroll factor
		# scroll=0: stays at base_pos (fixed to screen)
		# scroll=1.0: moves opposite to camera (scrolls with world)
		var screen_x = base_pos.x - game_state.camera_x * scroll_x
		var screen_y = base_pos.y - game_state.camera_y * scroll_y
		layer_node.position = Vector2(screen_x, screen_y)
	
	# Move entity container with camera (entities are in world coords, need 1:1 scroll)
	entity_container.position = Vector2(-game_state.camera_x, -game_state.camera_y)


func _create_debug_hud() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	debug_label = Label.new()
	debug_label.position = Vector2(8, 8)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	debug_label.add_theme_constant_override("shadow_offset_x", 1)
	debug_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(debug_label)


func _update_debug_hud() -> void:
	if debug_label == null:
		return
	
	var visible_entities = 0
	for e in active_entities:
		if e.visible:
			visible_entities += 1
	
	debug_label.text = """[%s] %s Stage %d
Player: (%d, %d)
Camera: (%d, %d)
Level: %dx%d
Entities: %d/%d visible
Frame: %d
[Arrows/WASD=Move, HOME=Respawn, F1=Debug]""" % [
		game_state.level_id,
		game_state.level_name,
		stage_index + 1,
		int(player.x),
		int(player.y),
		int(game_state.camera_x),
		int(game_state.camera_y),
		game_state.level_width,
		game_state.level_height,
		visible_entities,
		active_entities.size(),
		frame_count,
	]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				show_debug = not show_debug
				debug_label.visible = show_debug
			KEY_ESCAPE:
				get_tree().quit()
			KEY_R:
				# Reload level
				_initialize_and_load_level()
			KEY_HOME:
				# Return player to spawn
				player.x = float(game_state.spawn_x)
				player.y = float(game_state.spawn_y)
