extends Node2D

## Level Viewer - Demonstrates BLBArchive GDExtension for level rendering
##
## This script uses the BLBArchive class from the C99 engine to load and render
## level data directly in Godot without external tools.
##
## Controls:
##   Arrow keys - Move camera
##   R - Reload level
##   Space - Toggle auto-scroll
##   [ / ] - Previous/Next level
##   , / . - Previous/Next stage

@export_file("*.BLB") var blb_path: String = ""
@export var level_index: int = 2  # SCIE (Science Center)
@export var stage_index: int = 0
@export var auto_scroll: bool = true
@export var scroll_speed: float = 100.0

var blb: BLBArchive
var level_texture: ImageTexture
var level_sprite: Sprite2D
var camera: Camera2D
var scroll_offset: float = 0.0
var tile_cache: Dictionary = {}  # tile_index -> Image

func _ready() -> void:
	# Create camera
	camera = Camera2D.new()
	camera.position = Vector2(320, 240)  # PSX resolution center
	add_child(camera)
	camera.make_current()
	
	# Create sprite for level
	level_sprite = Sprite2D.new()
	level_sprite.centered = false
	add_child(level_sprite)
	
	# Set default BLB path if not specified
	if blb_path == "":
		var default_paths := [
			"res://assets/GAME.BLB",
			"/home/sam/projects/btm/disks/blb/GAME.BLB"
		]
		for path in default_paths:
			if FileAccess.file_exists(path):
				blb_path = path
				break
	
	if blb_path == "":
		push_warning("No BLB file found. Set blb_path in inspector.")
		return
	
	# Load and render
	load_blb()

func load_blb() -> void:
	blb = BLBArchive.new()
	
	var open_path := blb_path
	if blb_path.begins_with("res://"):
		open_path = ProjectSettings.globalize_path(blb_path)
	
	if not blb.open(open_path):
		push_error("Failed to open BLB: " + open_path)
		return
	
	print("Opened BLB: %s" % open_path)
	print("  Levels: %d" % blb.get_level_count())
	
	render_level()

func render_level() -> void:
	if not blb:
		return
	
	print("Loading level %d stage %d..." % [level_index, stage_index])
	
	if not blb.load_level(level_index, stage_index):
		push_error("Failed to load level %d stage %d" % [level_index, stage_index])
		return
	
	var tile_count := blb.get_tile_count()
	var layer_count := blb.get_layer_count()
	var bg_color_packed: int = blb.get_background_color()
	
	print("  Tiles: %d, Layers: %d" % [tile_count, layer_count])
	
	# Extract background color
	var bg_r := (bg_color_packed >> 0) & 0xFF
	var bg_g := (bg_color_packed >> 8) & 0xFF
	var bg_b := (bg_color_packed >> 16) & 0xFF
	
	# Find the main gameplay layer (usually layer 0 or 1)
	var main_layer_idx := 0
	var main_layer: Dictionary = blb.get_layer_info(main_layer_idx)
	
	if main_layer.is_empty():
		push_error("No valid layers found")
		return
	
	# Get layer dimensions
	var layer_width: int = main_layer.get("width", 20)
	var layer_height: int = main_layer.get("height", 15)
	
	print("  Layer 0: %dx%d tiles" % [layer_width, layer_height])
	
	# Build tile cache first
	build_tile_cache(tile_count)
	
	# Get tilemap data
	var tilemap_data: PackedByteArray = blb.get_layer_tilemap(main_layer_idx)
	if tilemap_data.is_empty():
		push_error("Failed to get tilemap data")
		return
	
	# Render the level
	var level_img := render_layer(tilemap_data, layer_width, layer_height, 
		Color8(bg_r, bg_g, bg_b))
	
	if level_img:
		level_texture = ImageTexture.create_from_image(level_img)
		level_sprite.texture = level_texture
		print("Level rendered: %dx%d pixels" % [level_img.get_width(), level_img.get_height()])

func build_tile_cache(tile_count: int) -> void:
	## Pre-render all tiles into a cache for fast compositing.
	tile_cache.clear()
	
	for i in range(tile_count):
		var tile_rgba: PackedByteArray = blb.render_tile(i)
		if tile_rgba.is_empty():
			continue
		
		var tile_size := blb.get_tile_size(i)
		var tile_img := Image.create_from_data(tile_size, tile_size, 
			false, Image.FORMAT_RGBA8, tile_rgba)
		tile_cache[i] = tile_img

func render_layer(tilemap: PackedByteArray, width: int, height: int, bg_color: Color) -> Image:
	## Render a layer to an Image using the tile cache.
	
	# Create output image (16x16 pixels per tile)
	var img_width := width * 16
	var img_height := height * 16
	var img := Image.create(img_width, img_height, false, Image.FORMAT_RGBA8)
	img.fill(bg_color)
	
	# Parse tilemap (array of u16 values)
	var tile_count := tilemap.size() / 2
	
	for i in range(mini(tile_count, width * height)):
		var tile_index: int = tilemap.decode_u16(i * 2)
		
		# Skip empty tiles
		if tile_index == 0 or tile_index == 0xFFFF:
			continue
		
		# Get tile image from cache
		if not tile_cache.has(tile_index):
			continue
		
		var tile_img: Image = tile_cache[tile_index]
		var tile_size: int = tile_img.get_width()
		
		# Calculate position
		var tx := (i % width) * 16
		var ty := (i / width) * 16
		
		# Blit tile to level image
		var src_rect := Rect2i(0, 0, tile_size, tile_size)
		img.blit_rect(tile_img, src_rect, Vector2i(tx, ty))
	
	return img

func _process(delta: float) -> void:
	if auto_scroll and level_texture != null:
		scroll_offset += scroll_speed * delta
		var max_scroll: float = level_texture.get_width() - 640
		if max_scroll > 0 and scroll_offset > max_scroll:
			scroll_offset = 0
		camera.position.x = scroll_offset + 320

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				camera.position.x -= 100
			KEY_RIGHT:
				camera.position.x += 100
			KEY_UP:
				camera.position.y -= 100
			KEY_DOWN:
				camera.position.y += 100
			KEY_R:
				render_level()
			KEY_SPACE:
				auto_scroll = not auto_scroll
			KEY_BRACKETLEFT:  # Previous level
				level_index = maxi(0, level_index - 1)
				render_level()
			KEY_BRACKETRIGHT:  # Next level
				if blb:
					level_index = mini(blb.get_level_count() - 1, level_index + 1)
				render_level()
			KEY_COMMA:  # Previous stage
				stage_index = maxi(0, stage_index - 1)
				render_level()
			KEY_PERIOD:  # Next stage
				stage_index += 1
				render_level()
