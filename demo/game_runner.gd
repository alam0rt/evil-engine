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
var active_entities: Array[Object] = []

# Layer data
var layers: Array[Dictionary] = []

# Tile collision (Asset 500 - from Ghidra GetTileAttributeAtPosition @ 0x800241f4)
# Header: offset_x, offset_y, width, height (all u16), then 1 byte per tile
var tile_attributes: PackedByteArray = PackedByteArray()
var tile_attr_width: int = 0   # Collision map width (tiles)
var tile_attr_height: int = 0  # Collision map height (tiles)
var tile_attr_offset_x: int = 0  # Tile X offset (subtracted from coords)
var tile_attr_offset_y: int = 0  # Tile Y offset (subtracted from coords)

# Collision attribute constants (from Ghidra PlayerCallback_800638d0)
# Floor is solid if: attr != 0 && attr <= 0x3B
# Values > 0x3B are triggers (checkpoints, spawn zones, etc.)
const TILE_EMPTY: int = 0x00
const TILE_SOLID_MAX: int = 0x3B  # Max value for solid floor
const TILE_SOLID: int = 0x02      # Common solid value
const TILE_CHECKPOINT: int = 0x53
const TILE_PLATFORM: int = 0x5B   # One-way platform (CLOU clouds)
const TILE_SPAWN_ZONE: int = 0x65

# Physics constants (estimated - see btm/docs/systems/player-physics.md)
const WALK_SPEED: float = 2.0       # pixels/frame
const JUMP_VELOCITY: float = -6.0   # initial upward velocity
const GRAVITY: float = 0.4          # pixels/frame²
const MAX_FALL_SPEED: float = 8.0   # terminal velocity

# Player state (mirrors g_pPlayerState @ 0x8009DC20)
# Per btm/docs/systems/player-system.md
var player_state: Dictionary = {
	"initialized": false,      # State initialized (offset 0x00)
	"active": true,            # Player is active (offset 0x01)
	"lives": 5,                # Current lives (offset 0x11)
	"powerup_flags": 0,        # Active powerups bitmask (offset 0x17)
	"shrink_mode": false,      # Player is shrunk (offset 0x18)
}

# Powerup flag constants (from player_state.powerup_flags)
const POWERUP_HALO: int = 0x01   # Invincibility
const POWERUP_TRAIL: int = 0x02  # Trail/glide effect

# Player entity (mirrors entity struct, 0x1B4 bytes for normal player)
# Per btm/docs/systems/player-system.md
var player: Dictionary = {
	"x": 0.0,                    # Pixel position (offset 0x68)
	"y": 0.0,                    # Pixel position (offset 0x6A)
	"vel_x": 0.0,                # X velocity (offset 0x160)
	"vel_y": 0.0,                # Y velocity (offset 0x162)
	"on_ground": false,
	"facing_left": false,        # Direction (offset 0x74)
	"width": 16,                 # Collision box (normal size)
	"height": 32,
	"invincibility_timer": 0,    # Damage invincibility (offset 0x128)
	"powerup_timer": 0,          # Powerup effect timer (offset 0x144)
	"damage_flag": false,        # Currently taking damage (offset 0x1AE)
	"is_dead": false,            # Death state (entity[0x5e] = 1)
	"state": 0,                  # State machine index (0=normal, 2=hit)
	"anim_index": 0,             # Current animation index
	"anim_frame": 0,             # Current frame in animation
	"anim_timer": 0,             # Frame delay counter
	"sprite_id": 0,              # Current sprite ID (from sprite table)
}
var player_node: Node2D        # Visual representation (Sprite2D or ColorRect)
var player_sprite: Sprite2D    # Actual sprite (if loaded)
var player_fallback: ColorRect # Fallback colored box

# Sprite data (from Asset 600 tertiary + primary)
var sprites: Array = []           # Combined sprite array
var sprite_lookup: Dictionary = {}  # Sprite ID -> sprite dict

# Player sprite IDs (from Ghidra DAT_8009c174)
# These are the sprite IDs used by normal player states
const PLAYER_SPRITE_IDS: Array[int] = [
	0x08208902,  # Default/idle
	0x48204012,  # Walking?
	0x856990A0,  # Jumping?
	0x0708A4A0,  # Landing?
	0x052AA082,  # Running?
	0x393C80C2,  # Ducking?
	0x1CF99931,  # Attack?
]

# Rendering
var viewport: SubViewport
var viewport_sprite: Sprite2D
var entity_container: Node2D
var layer_container: Node2D
var player_container: Node2D

# BLB access - prefer EVIL GDExtension over GDScript reader
var blb_archive: BLBArchive = null  # EVIL GDExtension (fast, for level lookup/tiles/layers)
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
	
	# Create entity container - gameplay z-order range (900-1100)
	# Per btm/docs/systems/rendering-order.md
	entity_container = Node2D.new()
	entity_container.name = "Entities"
	entity_container.z_index = 1000
	viewport.add_child(entity_container)
	
	# Create player container
	# PSX uses z=10000 but Godot max is 4096, so we use relative ordering
	# Player is always rendered on top via highest z_index in the container hierarchy
	player_container = Node2D.new()
	player_container.name = "Player"
	player_container.z_index = 4000  # Max practical value (Godot limit ~4096)
	viewport.add_child(player_container)
	
	# Create player visual node (will be updated with sprite later)
	player_node = Node2D.new()
	player_node.name = "PlayerVisual"
	player_container.add_child(player_node)
	
	# Create sprite child (for actual sprite rendering)
	player_sprite = Sprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.centered = false  # Use top-left origin like PSX
	player_sprite.visible = false   # Hidden until sprite loaded
	player_node.add_child(player_sprite)
	
	# Create fallback colored box
	player_fallback = ColorRect.new()
	player_fallback.name = "PlayerFallback"
	player_fallback.color = Color(0.2, 0.6, 1.0, 0.9)  # Blue
	player_fallback.size = Vector2(player.width, player.height)
	player_node.add_child(player_fallback)
	
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
	
	# Convert res:// path to filesystem path for EVIL library
	var fs_path = blb_path
	if blb_path.begins_with("res://"):
		fs_path = ProjectSettings.globalize_path(blb_path)
	
	# Open BLB with EVIL GDExtension (keep as member for later use)
	if blb_archive == null:
		blb_archive = BLBArchive.new()
	if not blb_archive.open(fs_path):
		push_error("[GameRunner] Failed to open BLB with EVIL library: %s" % fs_path)
		return
	print("[GameRunner] DEBUG: BLB opened, level_count=%d" % blb_archive.get_level_count())
	
	# Resolve level_id to level_index using EVIL library
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
	
	# Also load in EVIL library for fast tile/layer access
	if not blb_archive.load_level(level_index, stage_index):
		push_warning("[GameRunner] EVIL load_level failed, using GDScript fallback")
	
	# Load sprites from stage_data (Asset 600 tertiary + primary)
	_load_sprites(stage_data)
	
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
	
	var tile_header: Dictionary = stage_data.get("tile_header", {})
	var spawn_tile_x: int = tile_header.get("spawn_x", 0)
	var spawn_tile_y: int = tile_header.get("spawn_y", 0)
	
	# Get level dimensions from tile_header (for display/bounds)
	var level_w: int = tile_header.get("level_width", 20)
	var level_h: int = tile_header.get("level_height", 15)
	
	# Get tile attribute dimensions and offsets from Asset 500 header
	# (from Ghidra GetTileAttributeAtPosition @ 0x800241f4)
	tile_attr_offset_x = stage_data.get("tile_attr_offset_x", 0)
	tile_attr_offset_y = stage_data.get("tile_attr_offset_y", 0)
	tile_attr_width = stage_data.get("tile_attr_width", level_w)
	tile_attr_height = stage_data.get("tile_attr_height", level_h)
	
	# Store tile attributes (collision map - Asset 500)
	tile_attributes = stage_data.get("tile_attributes", PackedByteArray())
	if tile_attributes.size() > 0:
		print("[GameRunner] Loaded tile_attributes: %d bytes (grid %dx%d, offset %d,%d)" % [
			tile_attributes.size(), tile_attr_width, tile_attr_height,
			tile_attr_offset_x, tile_attr_offset_y])
		# Verify size matches dimensions
		if tile_attributes.size() != tile_attr_width * tile_attr_height:
			push_warning("[GameRunner] tile_attributes size mismatch!")
	else:
		push_warning("[GameRunner] No tile_attributes found - collision disabled!")
	
	# Convert to pixel coords (PSX formula from Ghidra)
	game_state.spawn_x = spawn_tile_x * TILE_SIZE + 8   # Center of tile
	game_state.spawn_y = spawn_tile_y * TILE_SIZE + 15  # Bottom of tile
	# Use the larger of tile_header or tile_attr dimensions for level bounds
	game_state.level_width = maxi(level_w, tile_attr_width) * TILE_SIZE
	game_state.level_height = maxi(level_h, tile_attr_height) * TILE_SIZE
	game_state.level_name = stage_data.get("level_name", "UNKNOWN")
	game_state.level_id = stage_data.get("level_id", "????")
	
	# Initialize player at spawn
	player.x = float(game_state.spawn_x)
	player.y = float(game_state.spawn_y)
	player.vel_x = 0.0
	player.vel_y = 0.0
	player.on_ground = false
	
	# Initialize player sprite (after sprites are loaded)
	_init_player_sprite()
	
	print("[GameRunner] InitPlayerSpawnPosition: (%d, %d)" % [game_state.spawn_x, game_state.spawn_y])


func _init_player_sprite() -> void:
	## Initialize player sprite from loaded sprite data
	## Mirrors InitPlayerSpriteAvailability @ 0x80059a70
	
	# Try to load the first player sprite
	var image: Image = decode_player_sprite_frame(0, 0)  # Animation 0, Frame 0
	
	if image != null:
		# Success - use actual sprite
		var texture := ImageTexture.create_from_image(image)
		player_sprite.texture = texture
		player_sprite.visible = true
		player_fallback.visible = false
		
		# Update player dimensions from sprite
		player.width = image.get_width()
		player.height = image.get_height()
		
		print("[GameRunner] Loaded player sprite: %dx%d" % [image.get_width(), image.get_height()])
	else:
		# Fallback to colored box
		player_sprite.visible = false
		player_fallback.visible = true
		player_fallback.size = Vector2(player.width, player.height)
		print("[GameRunner] Using fallback player sprite (no sprite data found)")


func _update_player_sprite() -> void:
	## Update player sprite based on current animation state
	
	# For now, just update flip based on facing direction
	if player_sprite.visible:
		player_sprite.flip_h = player.facing_left
		# Sprite offset: render_x, render_y from frame metadata
		# The sprite is drawn relative to entity position
		# Position is already handled in _update_camera_and_player_position
	else:
		# Update fallback color based on state
		if player.is_dead:
			player_fallback.color = Color(1.0, 0.2, 0.2, 0.9)  # Red
		elif player.damage_flag:
			player_fallback.color = Color(1.0, 0.6, 0.2, 0.9)  # Orange
		else:
			player_fallback.color = Color(0.2, 0.6, 1.0, 0.9)  # Blue


func _load_bg_color(_stage_data: Dictionary) -> void:
	## Mirrors LoadBGColorFromTileHeader
	## Sets the viewport clear color (visible where no layers cover)
	## Uses EVIL GDExtension for fast access
	
	var bg: Color = Color.BLACK
	
	if blb_archive != null and blb_archive.has_method("get_background_color"):
		var result = blb_archive.get_background_color()
		if result is Color:
			bg = result
		else:
			# Fallback to GDScript parsing
			var tile_header: Dictionary = _stage_data.get("tile_header", {})
			bg = Color8(
				tile_header.get("bg_r", 0),
				tile_header.get("bg_g", 0),
				tile_header.get("bg_b", 0)
			)
	else:
		# Fallback to GDScript parsing
		var tile_header: Dictionary = _stage_data.get("tile_header", {})
		bg = Color8(
			tile_header.get("bg_r", 0),
			tile_header.get("bg_g", 0),
			tile_header.get("bg_b", 0)
		)
	
	game_state.bg_color = bg
	
	# Set clear color - this shows through where layers don't cover
	RenderingServer.set_default_clear_color(bg)
	
	# Also set SubViewport's clear color
	viewport.transparent_bg = false
	
	print("[GameRunner] BG Color: RGB(%d, %d, %d)" % [int(bg.r8), int(bg.g8), int(bg.b8)])


func _load_entities(_stage_data: Dictionary) -> void:
	## Mirrors LoadEntitiesFromAsset501
	## Entities are now loaded via StageSceneBuilder as BLBEntityBase nodes
	## This function connects signals from entity nodes
	
	active_entities.clear()
	
	# Find Entities container created by StageSceneBuilder (in layer_container's scene)
	# We'll connect to entity signals for loose coupling (Godot best practice)
	print("[GameRunner] Entity signals will be connected after scene build")


func _load_sprites(stage_data: Dictionary) -> void:
	## Load sprites from Asset 600 (tertiary + primary)
	## Mirrors LookupSpriteById @ 0x8007bb10: checks tertiary first, then primary
	
	sprites.clear()
	sprite_lookup.clear()
	
	# Load tertiary sprites (stage-specific) - checked first in game
	var tertiary_sprites: Array = stage_data.get("sprites", [])
	for s in tertiary_sprites:
		sprites.append(s)
		if s.has("id"):
			sprite_lookup[s.id] = s
	
	# Load primary sprites (level-wide) - fallback in game
	var primary_sprites: Array = stage_data.get("primary_sprites", [])
	for s in primary_sprites:
		# Only add if not already in tertiary (tertiary takes precedence)
		if s.has("id") and not sprite_lookup.has(s.id):
			sprites.append(s)
			sprite_lookup[s.id] = s
	
	print("[GameRunner] Loaded %d sprites (%d tertiary, %d primary)" % [
		sprites.size(), tertiary_sprites.size(), primary_sprites.size()])
	
	# Check if any player sprite IDs are available
	var player_sprites_found: int = 0
	for sprite_id in PLAYER_SPRITE_IDS:
		if sprite_lookup.has(sprite_id):
			player_sprites_found += 1
	
	if player_sprites_found > 0:
		print("[GameRunner] Found %d player sprite IDs in level data" % player_sprites_found)
	else:
		print("[GameRunner] No player sprite IDs found - using fallback colored box")


func find_sprite_by_id(sprite_id: int) -> Dictionary:
	## Find sprite by ID (mirrors LookupSpriteById @ 0x8007bb10)
	return sprite_lookup.get(sprite_id, {})


func decode_player_sprite_frame(anim_idx: int, frame_idx: int) -> Image:
	## Decode a player sprite frame
	## Tries each player sprite ID until one is found
	
	for sprite_id in PLAYER_SPRITE_IDS:
		var sprite: Dictionary = find_sprite_by_id(sprite_id)
		if sprite.is_empty():
			continue
		
		# Use blb_reader to decode the frame
		if blb_reader != null and blb_reader.has_method("decode_sprite_frame"):
			var image: Image = blb_reader.decode_sprite_frame(sprite, anim_idx, frame_idx)
			if image != null:
				return image
	
	return null


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
		
		# Get layer count from EVIL library if available
		var evil_layer_count = 0
		if blb_archive != null:
			evil_layer_count = blb_archive.get_layer_count()
		
		print("[GameRunner] EVIL layer_count: %d, tile_layers children: %d" % [evil_layer_count, tile_layers.get_child_count()])
		
		# Store layer metadata for parallax updates - prefer EVIL GDExtension
		for i in range(tile_layers.get_child_count()):
			var layer_node = tile_layers.get_child(i)
			
			# Extract layer index from node name (e.g., "Layer_0")
			var layer_idx := i
			if layer_node.name.begins_with("Layer_"):
				layer_idx = int(layer_node.name.substr(6))
			
			# Get scroll factors from EVIL library
			var scroll_x := 65536
			var scroll_y := 65536
			if blb_archive != null and layer_idx < evil_layer_count:
				var evil_layer_info = blb_archive.get_layer_info(layer_idx)
				scroll_x = evil_layer_info.get("scroll_x", 65536)
				scroll_y = evil_layer_info.get("scroll_y", 65536)
			
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
	
	# Extract Entities container and connect signals
	var entities_node = stage_root.get_node_or_null("Entities")
	if entities_node:
		stage_root.remove_child(entities_node)
		entity_container.add_child(entities_node)
		
		# Connect to entity signals and build active_entities list
		_connect_entity_signals(entities_node)
	
	# Clean up the temporary root
	stage_root.queue_free()
	
	print("[GameRunner] Initialized %d layers, %d entities from StageSceneBuilder" % [layers.size(), active_entities.size()])


func _connect_entity_signals(entities_node: Node) -> void:
	## Connect entity signals for loose coupling (Godot best practice)
	## Entities emit signals, GameRunner responds
	
	active_entities.clear()
	
	for entity_node in entities_node.get_children():
		# Check if this is a BLBEntityBase-derived node
		if entity_node.has_method("entity_tick"):
			active_entities.append(entity_node)
			
			# Connect signals if they exist
			if entity_node.has_signal("collected"):
				entity_node.collected.connect(_on_entity_collected)
			if entity_node.has_signal("player_damaged"):
				entity_node.player_damaged.connect(_on_entity_player_damaged)
			if entity_node.has_signal("portal_activated"):
				entity_node.portal_activated.connect(_on_entity_portal_activated)
			if entity_node.has_signal("message_triggered"):
				entity_node.message_triggered.connect(_on_entity_message_triggered)
			if entity_node.has_signal("entity_killed"):
				entity_node.entity_killed.connect(_on_entity_killed)


func _on_entity_collected(entity: Node2D, score_value: int) -> void:
	## Called when player collects a collectible entity
	game_state["score"] = game_state.get("score", 0) + score_value
	print("[GameRunner] Collected! Score +%d (total: %d)" % [score_value, game_state.get("score", 0)])


func _on_entity_player_damaged(entity: Node2D, damage: int) -> void:
	## Called when an entity damages the player
	## Mirrors damage handling in PlayerStateCallback_2 @ 0x8006864c
	
	# Check if invincible (from timer or powerup)
	if player.invincibility_timer > 0:
		return
	if player_state.powerup_flags & POWERUP_HALO:
		return
	if player.is_dead:
		return
	
	print("[GameRunner] Player damaged by %s! -%d HP" % [entity.name, damage])
	
	# Enter hit/damage state
	player.damage_flag = true
	player.state = 2  # Hit state (PlayerStateCallback_2)
	
	# Apply knockback
	var knockback_x = -2.0 if player.facing_left else 2.0
	player.vel_x = knockback_x
	player.vel_y = -3.0  # Slight upward bounce
	
	# Start invincibility timer (about 2 seconds at 60fps)
	player.invincibility_timer = 120
	
	# Flash visual feedback
	_start_damage_flash()
	
	# Decrement lives
	player_state.lives -= 1
	print("[GameRunner] Lives remaining: %d" % player_state.lives)
	
	# Check for death
	if player_state.lives <= 0:
		_trigger_player_death()


func _start_damage_flash() -> void:
	## Start damage flash effect (RGB modulation)
	## PSX uses RGB at entity+0xF0-F5 for flash
	if player_node:
		# Flash red briefly
		var tween = create_tween()
		tween.tween_property(player_node, "color", Color(1.0, 0.3, 0.3, 0.9), 0.1)
		tween.tween_property(player_node, "color", Color(0.2, 0.6, 1.0, 0.9), 0.1)
		tween.set_loops(5)


func _trigger_player_death() -> void:
	## Triggers player death state
	## Mirrors Callback_80069ef4 from btm/docs/systems/player-system.md
	
	print("[GameRunner] Player died!")
	
	# Mark as dead (entity[0x5e] = 1)
	player.is_dead = true
	player.damage_flag = false
	
	# Clear movement
	player.vel_x = 0.0
	player.vel_y = 0.0
	
	# Death visual effect (PSX scales to 3x and plays death animation)
	if player_node:
		var tween = create_tween()
		# Scale up (death explosion effect in PSX)
		tween.tween_property(player_node, "scale", Vector2(3.0, 3.0), 0.3)
		tween.parallel().tween_property(player_node, "modulate:a", 0.0, 0.5)
		tween.tween_callback(_respawn_after_death)
	
	# Play death sound would go here
	# PlaySoundEffect(0x4810c2c4, 0xa0, 0)


func _respawn_after_death() -> void:
	## Respawn player after death
	## Mirrors RespawnAfterDeath @ 0x8007cfc0
	
	print("[GameRunner] Respawning...")
	
	# Reset player entity state
	player.is_dead = false
	player.damage_flag = false
	player.invincibility_timer = 60  # Brief invincibility on respawn
	player.state = 0  # Normal state
	
	# Clear powerups on death (per DecrementPlayerLives)
	player_state.powerup_flags = 0
	
	# Reset position to spawn/checkpoint
	player.x = float(game_state.spawn_x)
	player.y = float(game_state.spawn_y)
	player.vel_x = 0.0
	player.vel_y = 0.0
	
	# Reset visual
	if player_node:
		player_node.scale = Vector2.ONE
		player_node.modulate = Color.WHITE
		player_node.color = Color(0.2, 0.6, 1.0, 0.9)
	
	# Check game over
	if player_state.lives <= 0:
		print("[GameRunner] GAME OVER")
		# Would transition to game over screen
		player_state.lives = 5  # For now, just reset


func _update_player_timers() -> void:
	## Update player-related timers each frame
	
	# Invincibility countdown
	if player.invincibility_timer > 0:
		player.invincibility_timer -= 1
		# Blink effect during invincibility
		if player_node:
			player_node.visible = (player.invincibility_timer % 10) < 5
		if player.invincibility_timer == 0:
			player.damage_flag = false
			if player_node:
				player_node.visible = true
	
	# Powerup timer countdown
	if player.powerup_timer > 0:
		player.powerup_timer -= 1
		if player.powerup_timer == 0:
			# Powerup expired - clear flags
			player_state.powerup_flags = 0
			print("[GameRunner] Powerup expired")


func activate_powerup(powerup_type: int, duration: int = 600) -> void:
	## Activate a powerup effect
	## @param powerup_type: POWERUP_HALO or POWERUP_TRAIL
	## @param duration: frames (600 = 10 seconds at 60fps)
	
	player_state.powerup_flags |= powerup_type
	player.powerup_timer = duration
	
	if powerup_type & POWERUP_HALO:
		print("[GameRunner] Halo powerup activated (invincibility)")
		# Would create halo child entity here
	if powerup_type & POWERUP_TRAIL:
		print("[GameRunner] Trail powerup activated")
		# Would create trail child entity here


func _on_entity_portal_activated(entity: Node2D, destination: int) -> void:
	## Called when player enters a portal
	print("[GameRunner] Portal activated! Destination: %d" % destination)
	# TODO: Implement stage transitions


func _on_entity_message_triggered(entity: Node2D, message_id: int) -> void:
	## Called when player triggers a message/checkpoint
	print("[GameRunner] Message triggered: %d" % message_id)
	# TODO: Implement message display


func _on_entity_killed(entity: Node2D) -> void:
	## Called when an entity is killed
	print("[GameRunner] Entity killed: %s" % entity.name)


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
	## Player movement with physics and tile collision
	## Based on btm/docs/systems/player-physics.md
	## Camera centers on player (screen center = 160, 120)
	
	# Skip if dead
	if player.is_dead:
		return
	
	# Update timers (invincibility, powerups)
	_update_player_timers()
	
	# --- Horizontal Movement ---
	var move_x: float = 0.0
	if input_state.pad_current & PSXButton.LEFT:
		move_x = -WALK_SPEED
		player.facing_left = true
	elif input_state.pad_current & PSXButton.RIGHT:
		move_x = WALK_SPEED
		player.facing_left = false
	
	# Apply horizontal movement with wall collision
	if move_x != 0:
		var direction = 1 if move_x > 0 else -1
		if not check_wall(player.x, player.y, direction):
			player.x += move_x
	
	# --- Jump ---
	if player.on_ground and (input_state.pad_pressed & PSXButton.CROSS):
		player.vel_y = JUMP_VELOCITY
		player.on_ground = false
	
	# --- Gravity ---
	if not player.on_ground:
		player.vel_y += GRAVITY
		if player.vel_y > MAX_FALL_SPEED:
			player.vel_y = MAX_FALL_SPEED
	
	# --- Ceiling Check ---
	if player.vel_y < 0 and check_ceiling(player.x, player.y):
		player.vel_y = 0  # Bonk head
	
	# --- Apply Vertical Velocity with step-wise collision ---
	# Check for floors along the path to prevent tunneling through thin platforms
	if player.vel_y >= 0:  # Falling or standing
		var remaining_y: float = player.vel_y
		var step_size: float = 8.0  # Check every 8 pixels (half a tile)
		
		while remaining_y > 0:
			var step: float = minf(remaining_y, step_size)
			player.y += step
			remaining_y -= step
			
			# Check if we hit a floor
			if check_floor(player.x, player.y):
				# Snap to top of the tile we landed on
				var tile_y: int = int(player.y) / TILE_SIZE
				player.y = float(tile_y * TILE_SIZE)  # Top of tile
				player.vel_y = 0.0
				player.on_ground = true
				remaining_y = 0  # Stop moving
				break
		
		if player.vel_y != 0:
			player.on_ground = false
	else:
		# Moving upward - just apply velocity
		player.y += player.vel_y
		player.on_ground = false
	
	# --- Death Checks ---
	# Falling off bottom of level triggers death
	if player.y > game_state.level_height + 100:
		_trigger_player_death()
		return
	
	# Clamp player to level bounds (but don't kill for going past sides)
	player.x = clampf(player.x, player.width / 2.0, game_state.level_width - player.width / 2.0)
	
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
	
	# Update player sprite state (flip, animation, etc.)
	_update_player_sprite()


func _entity_tick_loop() -> void:
	## Mirrors EntityTickLoop (0x80020e1c)
	## Iterates active entity list and calls entity_tick()
	## Passes game_state for loose coupling (entities don't access GameRunner directly)
	
	# Build game state dict to pass to entities
	var entity_game_state: Dictionary = {
		"player_x": player.x,
		"player_y": player.y,
		"player_width": player.width,
		"player_height": player.height,
		"player_invincible": player.invincibility_timer > 0 or (player_state.powerup_flags & POWERUP_HALO) != 0,
		"player_is_dead": player.is_dead,
		"camera_x": game_state.camera_x,
		"camera_y": game_state.camera_y,
		"frame_count": frame_count,
		"input_state": input_state,
	}
	
	for entity in active_entities:
		# Entities now handle their own active state check
		if entity.has_method("entity_tick"):
			entity.entity_tick(entity_game_state)


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
	var active_count = 0
	for e in active_entities:
		if e.has_method("entity_tick") and e.get("active"):
			active_count += 1
		if e.visible:
			visible_entities += 1
	
	# Get tile at player feet for debug
	var tile_at_feet = get_tile_attribute(player.x, player.y + 1)
	var ground_str = "ground" if player.on_ground else "air"
	var score = game_state.get("score", 0)
	var state_str = "DEAD" if player.is_dead else ("HIT" if player.damage_flag else "OK")
	var powerup_str = ""
	if player_state.powerup_flags & POWERUP_HALO:
		powerup_str += "HALO "
	if player_state.powerup_flags & POWERUP_TRAIL:
		powerup_str += "TRAIL "
	if powerup_str == "":
		powerup_str = "-"
	
	debug_label.text = """[%s] %s Stage %d  Score: %d  Lives: %d
Player: (%d, %d) vel_y=%.1f %s %s
Powerups: %s  Invuln: %d
Tile@feet: 0x%02X
Camera: (%d, %d)
Level: %dx%d
Entities: %d active, %d visible / %d total
Frame: %d
[Arrows=Move, X/Space=Jump, HOME=Respawn, F1=Debug]""" % [
		game_state.level_id,
		game_state.level_name,
		stage_index + 1,
		score,
		player_state.lives,
		int(player.x),
		int(player.y),
		player.vel_y,
		ground_str,
		state_str,
		powerup_str,
		player.invincibility_timer,
		tile_at_feet,
		int(game_state.camera_x),
		int(game_state.camera_y),
		game_state.level_width,
		game_state.level_height,
		active_count,
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
				player.vel_x = 0.0
				player.vel_y = 0.0


# =============================================================================
# Tile Collision System
# Based on Ghidra GetTileAttributeAtPosition @ 0x800241f4
# =============================================================================

func get_tile_attribute(pixel_x: float, pixel_y: float) -> int:
	## Get collision attribute at a pixel position
	## Mirrors GetTileAttributeAtPosition @ 0x800241f4
	##
	## Ghidra logic:
	##   tile_x = (pixel_x >> 4) - offset_x
	##   tile_y = (pixel_y >> 4) - offset_y
	##   if (tile_x < 0 or tile_x >= width or tile_y < 0 or tile_y >= height): return 0
	##   return data[tile_y * width + tile_x]
	##
	## Returns: attribute byte (0x00=empty, 0x02=solid, 0x5B=platform, etc.)
	
	if tile_attributes.size() == 0:
		return TILE_EMPTY
	
	# Convert pixel to tile coords and apply offsets (from Ghidra)
	var tile_x: int = (int(pixel_x) >> 4) - tile_attr_offset_x
	var tile_y: int = (int(pixel_y) >> 4) - tile_attr_offset_y
	
	# Bounds check (matches Ghidra: return 0 if out of bounds)
	if tile_x < 0 or tile_x >= tile_attr_width:
		return TILE_EMPTY
	if tile_y < 0 or tile_y >= tile_attr_height:
		return TILE_EMPTY
	
	var index: int = tile_y * tile_attr_width + tile_x
	if index < 0 or index >= tile_attributes.size():
		return TILE_EMPTY
	
	return tile_attributes[index]


func is_solid_at(pixel_x: float, pixel_y: float) -> bool:
	## Check if position has solid collision
	## From Ghidra: solid if attr != 0 && attr <= 0x3B
	var attr := get_tile_attribute(pixel_x, pixel_y)
	return attr != TILE_EMPTY and attr <= TILE_SOLID_MAX


func is_platform_at(pixel_x: float, pixel_y: float) -> bool:
	## Check if position is a one-way platform (0x5B)
	return get_tile_attribute(pixel_x, pixel_y) == TILE_PLATFORM


func is_floor_solid(attr: int) -> bool:
	## Check if a tile attribute represents solid ground
	## From Ghidra PlayerCallback_800638d0: solid if attr != 0 && attr <= 0x3B
	return attr != TILE_EMPTY and attr <= TILE_SOLID_MAX


func check_floor(x: float, y: float) -> bool:
	## Check if there's a floor below position
	## Uses Y+2 check point from Ghidra (just below feet)
	var attr := get_tile_attribute(x, y + 2)  # Y+2 from Ghidra
	
	# Solid floor: 0x01-0x3B (includes 0x02 solid tiles)
	# Platform: 0x5B (one-way, only if falling)
	return is_floor_solid(attr) or attr == TILE_PLATFORM


func check_wall(x: float, y: float, direction: int) -> bool:
	## Check wall collision at multiple heights (like PSX CheckWallCollision @ 0x80059bc8)
	## direction: -1 for left, +1 for right
	## Checks 4 points vertically: Y-15, Y-16, Y-32, Y-48
	## Returns true if ANY point hits solid (attr 0x01-0x3B)
	var check_x := x + direction * 8  # Check 8 pixels in move direction
	
	for offset in [15, 16, 32, 48]:
		var attr := get_tile_attribute(check_x, y - offset)
		if is_floor_solid(attr):  # Same range check as floor
			return true
	return false


func check_ceiling(x: float, y: float) -> bool:
	## Check for ceiling collision above player head
	var attr := get_tile_attribute(x, y - 48)
	return is_floor_solid(attr)
