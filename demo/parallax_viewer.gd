extends Node2D

## Parallax Level Viewer - PSX-accurate viewport with parallax scrolling
##
## Renders each layer separately and applies authentic parallax scrolling
## using the same 16.16 fixed-point factors as the original PSX code.
##
## PSX viewport: 320x240 pixels
## Scroll factors: 0x10000 (65536) = 1.0 = moves with camera
##                 0x8000 (32768) = 0.5 = half-speed parallax

const EntitySpritesClass = preload("res://addons/blb_importer/game_data/entity_sprites.gd")

const PSX_WIDTH: int = 320
const PSX_HEIGHT: int = 240
const FIXED_POINT_SCALE: float = 65536.0  # 16.16 fixed point

@export_file("*.BLB") var blb_path: String = ""
@export var level_index: int = 2  # SCIE (Science Center)
@export var stage_index: int = 0
@export var auto_scroll: bool = true
@export var scroll_speed: float = 80.0
@export var scale_factor: int = 2  # Window scaling (320x240 * 2 = 640x480)

# Level data
var level_name: String = ""
var level_width: int = 0
var level_height: int = 0
var spawn_x: int = 0
var spawn_y: int = 0
var bg_color: Color = Color.BLACK
var entity_count: int = 0

# Entities
var entities: Array[Dictionary] = []
@export var show_entities: bool = true

# Layers
var layers: Array[Dictionary] = []
var layer_sprites: Array[Sprite2D] = []

# Camera
var camera_x: float = 0.0
var camera_y: float = 0.0

# Viewport
var viewport: SubViewport
var viewport_sprite: Sprite2D
var entity_overlay: Node2D  # For drawing entity bounding boxes

# HUD
var hud_label: Label
@export var show_hud: bool = true

# Fit-to-window mode
var fit_to_window: bool = false

# Entity sprites
var entity_textures: Dictionary = {}  # entity_type -> Texture2D
@export var show_entity_sprites: bool = true  # Show actual sprites vs bounding boxes
@export var extracted_path: String = "/home/sam/projects/btm/extracted"  # Path to extracted assets

# Level selection menu
var menu_visible: bool = false
var menu_panel: Panel
var menu_list: ItemList
var menu_stage_list: ItemList
var menu_selected_level: int = 0

func _ready() -> void:
	print("[ParallaxViewer] Starting up...")
	
	# Parse command-line arguments: --level N --stage N
	parse_command_line_args()
	
	# Set window size
	get_window().size = Vector2i(PSX_WIDTH * scale_factor, PSX_HEIGHT * scale_factor)
	get_window().title = "Skullmonkeys Level Viewer (PSX 320x240)"
	print("[ParallaxViewer] Window size: %dx%d (scale %d)" % [PSX_WIDTH * scale_factor, PSX_HEIGHT * scale_factor, scale_factor])
	
	# Create SubViewport for PSX resolution
	viewport = SubViewport.new()
	viewport.size = Vector2i(PSX_WIDTH, PSX_HEIGHT)
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	print("[ParallaxViewer] Created viewport %dx%d" % [PSX_WIDTH, PSX_HEIGHT])
	
	# Create sprite to display the viewport
	viewport_sprite = Sprite2D.new()
	viewport_sprite.texture = viewport.get_texture()
	viewport_sprite.centered = false
	viewport_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(viewport_sprite)
	
	# Create entity overlay (draws on top of layers, inside viewport)
	entity_overlay = EntityOverlay.new()
	entity_overlay.viewer = self
	viewport.add_child(entity_overlay)
	
	# Create HUD overlay
	create_hud()
	
	# Render the level layers
	if blb_path != "":
		render_layers()
	else:
		var default_path = "/home/sam/projects/btm/disks/blb/GAME.BLB"
		if FileAccess.file_exists(default_path):
			blb_path = default_path
			render_layers()
		else:
			push_warning("No BLB file specified. Set blb_path in inspector.")

func parse_command_line_args() -> void:
	## Parse command-line arguments for level/stage selection
	## Usage: godot --path . scene.tscn -- --level 5 --stage 2
	var args = OS.get_cmdline_user_args()
	print("[ParallaxViewer] Command-line args: %s" % [args])
	
	var i = 0
	while i < args.size():
		var arg = args[i]
		if arg == "--level" or arg == "-l":
			if i + 1 < args.size():
				var val = int(args[i + 1])
				if val >= 0 and val < 26:
					level_index = val
					print("[ParallaxViewer] Set level to %d (%s)" % [level_index, EntitySpritesClass.get_level_folder(level_index)])
				else:
					push_warning("Invalid level index: %d (must be 0-25)" % val)
				i += 1
		elif arg == "--stage" or arg == "-s":
			if i + 1 < args.size():
				var val = int(args[i + 1])
				if val >= 0 and val < 6:
					stage_index = val
					print("[ParallaxViewer] Set stage to %d" % stage_index)
				else:
					push_warning("Invalid stage index: %d (must be 0-5)" % val)
				i += 1
		elif arg == "--blb" or arg == "-b":
			if i + 1 < args.size():
				blb_path = args[i + 1]
				print("[ParallaxViewer] Set BLB path to %s" % blb_path)
				i += 1
		elif arg == "--help" or arg == "-h":
			print("Usage: godot --path . demo/parallax_viewer.tscn -- [OPTIONS]")
			print("Options:")
			print("  --level N, -l N   Load level N (0-25)")
			print("  --stage N, -s N   Load stage N (0-5)")
			print("  --blb PATH, -b    Path to GAME.BLB file")
			print("  --help, -h        Show this help")
			print("")
			print("Levels: MENU(0), GLEN(1), SCIE(2), CRYS(3), WEED(4), HEAD(5),")
			print("        BOIL(6), TMPL(7), CAVE(8), FOOD(9), CSTL(10), CLOU(11),")
			print("        PHRO(12), WIZZ(13), BRG1(14), MOSS(15), SOAR(16), EGGS(17),")
			print("        FINN(18), GLID(19), KLOG(20), SNOW(21), EVIL(22), RUNN(23),")
			print("        MEGA(24), SEVN(25)")
			get_tree().quit()
			return
		i += 1

func create_hud() -> void:
	# Create a CanvasLayer for HUD (renders on top of everything)
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	# Create label for stats
	hud_label = Label.new()
	hud_label.position = Vector2(8, 8)
	hud_label.add_theme_font_size_override("font_size", 14)
	hud_label.add_theme_color_override("font_color", Color.WHITE)
	hud_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud_label.add_theme_constant_override("shadow_offset_x", 1)
	hud_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(hud_label)
	
	# Create level selection menu
	create_level_menu(canvas)

func create_level_menu(canvas: CanvasLayer) -> void:
	# Main panel
	menu_panel = Panel.new()
	menu_panel.size = Vector2(400, 350)
	menu_panel.position = Vector2(
		(PSX_WIDTH * scale_factor - 400) / 2,
		(PSX_HEIGHT * scale_factor - 350) / 2
	)
	menu_panel.visible = false
	canvas.add_child(menu_panel)
	
	# Title label
	var title = Label.new()
	title.text = "Select Level"
	title.position = Vector2(150, 10)
	title.add_theme_font_size_override("font_size", 18)
	menu_panel.add_child(title)
	
	# Level list (left side)
	var level_label = Label.new()
	level_label.text = "Level:"
	level_label.position = Vector2(10, 40)
	menu_panel.add_child(level_label)
	
	menu_list = ItemList.new()
	menu_list.position = Vector2(10, 60)
	menu_list.size = Vector2(180, 250)
	menu_list.select_mode = ItemList.SELECT_SINGLE
	
	# Populate level list
	for i in range(EntitySpritesClass.LEVEL_FOLDERS.size()):
		var folder = EntitySpritesClass.LEVEL_FOLDERS[i]
		menu_list.add_item("%02d: %s" % [i, folder])
	
	menu_list.select(level_index)
	menu_list.item_selected.connect(_on_level_selected)
	menu_panel.add_child(menu_list)
	
	# Stage list (right side)
	var stage_label = Label.new()
	stage_label.text = "Stage:"
	stage_label.position = Vector2(210, 40)
	menu_panel.add_child(stage_label)
	
	menu_stage_list = ItemList.new()
	menu_stage_list.position = Vector2(210, 60)
	menu_stage_list.size = Vector2(180, 150)
	menu_stage_list.select_mode = ItemList.SELECT_SINGLE
	
	# Populate stage list
	for i in range(6):
		menu_stage_list.add_item("Stage %d" % i)
	
	menu_stage_list.select(stage_index)
	menu_stage_list.item_selected.connect(_on_stage_selected)
	menu_panel.add_child(menu_stage_list)
	
	# Load button
	var load_btn = Button.new()
	load_btn.text = "Load Level"
	load_btn.position = Vector2(210, 230)
	load_btn.size = Vector2(180, 40)
	load_btn.pressed.connect(_on_load_pressed)
	menu_panel.add_child(load_btn)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close (Tab/Esc)"
	close_btn.position = Vector2(210, 280)
	close_btn.size = Vector2(180, 30)
	close_btn.pressed.connect(toggle_level_menu)
	menu_panel.add_child(close_btn)

func toggle_level_menu() -> void:
	menu_visible = not menu_visible
	menu_panel.visible = menu_visible
	auto_scroll = false if menu_visible else auto_scroll
	
	if menu_visible:
		# Update selection to current level/stage
		menu_list.select(level_index)
		menu_list.ensure_current_is_visible()
		menu_stage_list.select(stage_index)
		menu_selected_level = level_index

func _on_level_selected(idx: int) -> void:
	menu_selected_level = idx

func _on_stage_selected(idx: int) -> void:
	pass  # Stage selection is read when loading

func _on_load_pressed() -> void:
	level_index = menu_list.get_selected_items()[0] if menu_list.get_selected_items().size() > 0 else level_index
	stage_index = menu_stage_list.get_selected_items()[0] if menu_stage_list.get_selected_items().size() > 0 else stage_index
	toggle_level_menu()
	render_layers()

func update_window_scaling() -> void:
	## Toggle between PSX mode (fixed scale) and fit-to-window mode
	if fit_to_window:
		# Scale viewport to fit entire level in window
		if level_width > 0 and level_height > 0:
			# Calculate scale to fit level in window while maintaining aspect ratio
			var window_size = get_window().size
			var scale_x = float(window_size.x) / float(level_width)
			var scale_y = float(window_size.y) / float(level_height)
			var fit_scale = min(scale_x, scale_y)
			
			# Resize viewport to show entire level
			viewport.size = Vector2i(level_width, level_height)
			viewport_sprite.scale = Vector2(fit_scale, fit_scale)
			
			# Center in window
			var scaled_w = level_width * fit_scale
			var scaled_h = level_height * fit_scale
			viewport_sprite.position = Vector2(
				(window_size.x - scaled_w) / 2,
				(window_size.y - scaled_h) / 2
			)
			
			# Lock camera to origin
			camera_x = 0
			camera_y = 0
			auto_scroll = false
			
			get_window().title = "Skullmonkeys - %s (Fit to Window)" % level_name
	else:
		# Restore PSX mode
		viewport.size = Vector2i(PSX_WIDTH, PSX_HEIGHT)
		viewport_sprite.scale = Vector2(scale_factor, scale_factor)
		viewport_sprite.position = Vector2.ZERO
		get_window().size = Vector2i(PSX_WIDTH * scale_factor, PSX_HEIGHT * scale_factor)
		get_window().title = "Skullmonkeys Level Viewer (PSX 320x240)"

func update_hud() -> void:
	if not show_hud or hud_label == null:
		hud_label.visible = false
		return
	
	hud_label.visible = true
	var cam_tile_x = int(camera_x / 16)
	var cam_tile_y = int(camera_y / 16)
	var entities_str = "ON" if show_entities else "OFF"
	var fit_str = "FIT" if fit_to_window else "PSX"
	
	hud_label.text = """Level: %s
Index: %d  Stage: %d  (%s)
Size: %dx%d px
Layers: %d  Entities: %d (%s)
Camera: (%d, %d) tile (%d, %d)
[Tab/L] Level Menu  [H]UD  [E]ntities
[Space] Scroll  [S]pawn  [F]it  [R]eload""" % [
		level_name,
		level_index, stage_index, fit_str,
		level_width, level_height,
		layers.size(), entities.size(), entities_str,
		int(camera_x), int(camera_y), cam_tile_x, cam_tile_y
	]

func render_layers() -> void:
	var level_name_str = EntitySpritesClass.get_level_folder(level_index)
	print("")
	print("========================================")
	print("[ParallaxViewer] Loading level %d (%s) stage %d" % [level_index, level_name_str, stage_index])
	print("[ParallaxViewer] BLB file: %s" % blb_path)
	print("========================================")
	
	var render_tool = ProjectSettings.globalize_path("res://build/render_layers")
	var output_dir = "/tmp/evil_layers"
	
	# Check if tool exists
	if not FileAccess.file_exists(render_tool):
		push_error("[ParallaxViewer] render_layers tool not found at: " + render_tool)
		return
	print("[ParallaxViewer] Using render tool: %s" % render_tool)
	
	# Create output directory
	DirAccess.make_dir_recursive_absolute(output_dir)
	print("[ParallaxViewer] Output directory: %s" % output_dir)
	
	# Run the render tool
	var args = [blb_path, str(level_index), str(stage_index), output_dir]
	print("[ParallaxViewer] Running: %s %s" % [render_tool, " ".join(args)])
	var output = []
	var exit_code = OS.execute(render_tool, args, output, true)
	
	if exit_code != 0:
		push_error("[ParallaxViewer] render_layers failed with exit code %d" % exit_code)
		push_error("[ParallaxViewer] Output: %s" % str(output))
		return
	print("[ParallaxViewer] Render tool completed successfully")
	
	# Load metadata
	print("[ParallaxViewer] Loading metadata...")
	load_metadata(output_dir + "/metadata.txt")
	print("[ParallaxViewer] Parsed %d layers, %d entities" % [layers.size(), entities.size()])
	
	# Set background color
	print("[ParallaxViewer] Background color: RGB(%d, %d, %d)" % [int(bg_color.r * 255), int(bg_color.g * 255), int(bg_color.b * 255)])
	RenderingServer.set_default_clear_color(bg_color)
	viewport.transparent_bg = false
	
	# Create background ColorRect inside viewport
	var bg_rect = ColorRect.new()
	bg_rect.color = bg_color
	bg_rect.size = Vector2(PSX_WIDTH, PSX_HEIGHT)
	bg_rect.z_index = -100  # Behind everything
	viewport.add_child(bg_rect)
	viewport.move_child(bg_rect, 0)  # Move to back
	
	# Load each layer image
	print("[ParallaxViewer] Loading layer images...")
	load_layer_images(output_dir)
	
	# Start camera at spawn point
	camera_x = clamp(spawn_x - PSX_WIDTH / 2.0, 0, level_width - PSX_HEIGHT)
	camera_y = clamp(spawn_y - PSX_HEIGHT / 2.0, 0, level_height - PSX_HEIGHT)
	print("[ParallaxViewer] Initial camera: (%.1f, %.1f)" % [camera_x, camera_y])
	
	# Load entity sprites from extracted folder
	print("[ParallaxViewer] Loading entity sprites...")
	load_entity_sprites()
	
	print("")
	print("[ParallaxViewer] === Level loaded ===")
	print("[ParallaxViewer] Level: %s (index %d, stage %d)" % [level_name, level_index, stage_index])
	print("[ParallaxViewer] Size: %dx%d pixels, spawn at (%d, %d)" % [level_width, level_height, spawn_x, spawn_y])
	print("[ParallaxViewer] Layers: %d, Entities: %d, Entity textures: %d" % [layers.size(), entities.size(), entity_textures.size()])
	print("========================================")
	print("")

func load_metadata(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[ParallaxViewer] Cannot open metadata: " + path)
		return
	
	print("[ParallaxViewer] Reading metadata from: %s" % path)
	layers.clear()
	entities.clear()
	var current_layer: Dictionary = {}
	var current_entity: Dictionary = {}
	var in_entity: bool = false
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		
		# Section header
		if line.begins_with("[layer_"):
			if current_layer.size() > 0:
				layers.append(current_layer)
			if current_entity.size() > 0:
				entities.append(current_entity)
			current_layer = {}
			current_entity = {}
			in_entity = false
			continue
		
		if line.begins_with("[entity_"):
			if current_layer.size() > 0:
				layers.append(current_layer)
			if current_entity.size() > 0:
				entities.append(current_entity)
			current_layer = {}
			current_entity = {}
			in_entity = true
			continue
		
		# Key=value parsing
		var parts = line.split("=", true, 1)
		if parts.size() != 2:
			continue
		
		var key = parts[0]
		var value = parts[1]
		
		# Entity properties
		if in_entity:
			match key:
				"x1", "y1", "x2", "y2", "x_center", "y_center", "type", "variant", "layer":
					current_entity[key] = int(value)
			continue
		
		# Global properties
		match key:
			"level_name":
				level_name = value
			"level_width":
				level_width = int(value)
			"level_height":
				level_height = int(value)
			"spawn_x":
				spawn_x = int(value)
			"spawn_y":
				spawn_y = int(value)
			"entity_count":
				entity_count = int(value)
			"bg_r":
				bg_color.r = int(value) / 255.0
			"bg_g":
				bg_color.g = int(value) / 255.0
			"bg_b":
				bg_color.b = int(value) / 255.0
			# Layer properties
			"width", "height", "x_offset", "y_offset", "scroll_x", "scroll_y", "layer_type":
				current_layer[key] = int(value)
			"file":
				current_layer["file"] = value
	
	# Add last section
	if current_layer.size() > 0:
		layers.append(current_layer)
	if current_entity.size() > 0:
		entities.append(current_entity)
	
	file.close()

func load_layer_images(dir_path: String) -> void:
	# Clear existing sprites
	print("[ParallaxViewer] Clearing %d existing layer sprites" % layer_sprites.size())
	for sprite in layer_sprites:
		sprite.queue_free()
	layer_sprites.clear()
	
	for i in range(layers.size()):
		var layer = layers[i]
		var img_path = dir_path + "/" + layer.get("file", "layer_%d.rgba" % i)
		
		var img = load_layer_image(img_path)
		if img == null:
			push_error("[ParallaxViewer] Failed to load layer %d from %s" % [i, img_path])
			continue
		
		var texture = ImageTexture.create_from_image(img)
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		# Add to viewport (layers render in order, back to front)
		viewport.add_child(sprite)
		layer_sprites.append(sprite)
		
		var scroll_x = layer.scroll_x / FIXED_POINT_SCALE
		var scroll_y = layer.scroll_y / FIXED_POINT_SCALE
		var layer_type = "FG" if scroll_x >= 1.0 else ("BG" if scroll_x > 0 else "STATIC")
		print("  [Layer %d] %dx%d %s scroll=(%.4f, %.4f) offset=(%d, %d)" % [
			i, layer.width, layer.height, layer_type,
			scroll_x, scroll_y,
			layer.x_offset, layer.y_offset
		])

func load_layer_image(path: String) -> Image:
	## Load layer image - supports both RGBA (with alpha) and PPM (no alpha) formats
	if path.ends_with(".rgba"):
		return load_rgba(path)
	else:
		return load_ppm(path)

func load_rgba(path: String) -> Image:
	## Load raw RGBA format: "RGBA" magic (4 bytes), width (u32 LE), height (u32 LE), then pixels
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	
	# Read and verify magic
	var magic = file.get_buffer(4)
	if magic.size() < 4 or magic[0] != 0x52 or magic[1] != 0x47 or magic[2] != 0x42 or magic[3] != 0x41:
		push_warning("Invalid RGBA magic in " + path)
		return null
	
	# Read dimensions (little-endian u32)
	var width = file.get_32()
	var height = file.get_32()
	
	# Read pixel data (RGBA)
	var rgba_data = file.get_buffer(width * height * 4)
	file.close()
	
	if rgba_data.size() != width * height * 4:
		push_warning("Incomplete RGBA data in " + path)
		return null
	
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba_data)

func load_ppm(path: String) -> Image:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	
	# Read PPM header
	var magic = file.get_line()
	if magic != "P6":
		return null
	
	var dimensions = file.get_line().split(" ")
	var width = int(dimensions[0])
	var height = int(dimensions[1])
	var _max_val = int(file.get_line())
	
	# Read pixel data (RGB)
	var rgb_data = file.get_buffer(width * height * 3)
	file.close()
	
	# Convert RGB to RGBA
	var rgba_data = PackedByteArray()
	rgba_data.resize(width * height * 4)
	for j in range(width * height):
		rgba_data[j * 4 + 0] = rgb_data[j * 3 + 0]
		rgba_data[j * 4 + 1] = rgb_data[j * 3 + 1]
		rgba_data[j * 4 + 2] = rgb_data[j * 3 + 2]
		rgba_data[j * 4 + 3] = 255
	
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba_data)

func load_entity_sprites() -> void:
	## Load entity sprites from the btm/extracted folder
	## Uses EntitySprites class for type → sprite ID mapping
	entity_textures.clear()
	
	# Get the level folder name
	var level_folder = EntitySpritesClass.get_level_folder(level_index)
	if level_folder == "":
		push_warning("Invalid level index for sprite loading: %d" % level_index)
		return
	
	var stage_folder = "stage%d" % stage_index
	var sprites_path = "%s/%s/%s/sprites" % [extracted_path, level_folder, stage_folder]
	
	# Check if sprites folder exists
	var dir = DirAccess.open(sprites_path)
	if dir == null:
		print("No sprites folder at: %s" % sprites_path)
		return
	
	# Scan for sprite files and build a lookup by sprite ID
	var sprite_files: Dictionary = {}  # sprite_id -> first frame filename
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		# Only load PNGs (Godot doesn't support GIF loading)
		if filename.ends_with(".png"):
			# Parse sprite ID from filename: sprite_<id>_anim<xx>_f<xx>.png
			if filename.begins_with("sprite_"):
				var parts = filename.replace("sprite_", "").split("_")
				if parts.size() >= 1:
					var sprite_id = int(parts[0])
					# Prefer first frame (_f00) or single frame files
					if sprite_id not in sprite_files or filename.contains("_f00") or not filename.contains("_f"):
						sprite_files[sprite_id] = sprites_path + "/" + filename
		filename = dir.get_next()
	dir.list_dir_end()
	
	print("Found %d sprite IDs in %s" % [sprite_files.size(), sprites_path])
	
	# Load textures for known entity types using EntitySprites mapping
	for entity_type in EntitySpritesClass.ENTITY_INFO:
		var sprite_id = EntitySpritesClass.get_sprite_id(entity_type)
		if sprite_id != null and sprite_id in sprite_files:
			var file_path = sprite_files[sprite_id]
			var img = Image.load_from_file(file_path)
			if img != null:
				var tex = ImageTexture.create_from_image(img)
				entity_textures[entity_type] = tex
				print("  Loaded sprite for %s (type %d)" % [EntitySpritesClass.get_short_name(entity_type), entity_type])
	
	# Also load all other sprites for display (store by sprite_id for future use)
	var extra_loaded = 0
	for sprite_id in sprite_files:
		# Skip if we already have this as an entity type texture
		var already_loaded = false
		for et in entity_textures:
			if et >= 0:  # entity type keys are positive
				var sid = EntitySpritesClass.get_sprite_id(et)
				if sid == sprite_id:
					already_loaded = true
					break
		if not already_loaded:
			var file_path = sprite_files[sprite_id]
			var img = Image.load_from_file(file_path)
			if img != null:
				var tex = ImageTexture.create_from_image(img)
				# Store by negative sprite_id to distinguish from entity_type keys
				entity_textures[-sprite_id] = tex
				extra_loaded += 1
	
	print("  Total: %d entity type sprites, %d extra sprites" % [entity_textures.size() - extra_loaded, extra_loaded])

func _process(delta: float) -> void:
	if layers.is_empty():
		return
	
	# Auto-scroll
	if auto_scroll:
		camera_x += scroll_speed * delta
		if camera_x > level_width - PSX_WIDTH:
			camera_x = 0
	
	# Update layer positions with parallax
	update_parallax()
	
	# Update HUD
	update_hud()

func update_parallax() -> void:
	## Apply parallax scrolling to each layer
	## PSX parallax formula: screen_pos = layer_offset - camera_pos * scroll_factor
	## 
	## For scroll=0 (static): Layer is fixed to viewport, doesn't move with camera
	## For scroll=1 (main): Layer moves 1:1 with camera (normal world scrolling)
	## For scroll<1 (parallax): Layer moves slower than camera (distant background)
	## For scroll>1 (foreground): Layer moves faster than camera
	##
	## The x_offset/y_offset define where the layer origin is in world space.
	## Layers smaller than the level are typically centered or tiled.
	
	for i in range(layers.size()):
		if i >= layer_sprites.size():
			continue
		
		var layer = layers[i]
		var sprite = layer_sprites[i]
		
		# Get scroll factors (16.16 fixed point, 0 = static, 65536 = 1.0)
		var scroll_x_raw: int = layer.get("scroll_x", 65536)
		var scroll_y_raw: int = layer.get("scroll_y", 65536)
		var scroll_x: float = float(scroll_x_raw) / FIXED_POINT_SCALE
		var scroll_y: float = float(scroll_y_raw) / FIXED_POINT_SCALE
		
		# Get layer offsets in pixels (already converted in metadata)
		var x_offset: float = layer.get("x_offset", 0)
		var y_offset: float = layer.get("y_offset", 0)
		
		# Get layer dimensions
		var layer_w: float = layer.get("width", 0)
		var layer_h: float = layer.get("height", 0)
		
		if scroll_x_raw == 0 and scroll_y_raw == 0:
			# Static layer: locked to viewport, doesn't move with camera
			# Position is relative to viewport origin (0,0 = top-left of screen)
			sprite.position = Vector2(x_offset, y_offset)
		else:
			# Parallax layer: moves relative to camera based on scroll factor
			# 
			# For a layer that's smaller than the level, we need to calculate
			# how much the layer should scroll relative to the camera.
			#
			# The formula calculates the apparent position of the layer's origin
			# when viewed through the camera at the current position.
			var parallax_x: float = x_offset - camera_x * scroll_x
			var parallax_y: float = y_offset - camera_y * scroll_y
			sprite.position = Vector2(parallax_x, parallax_y)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				camera_x = max(0, camera_x - 50)
				auto_scroll = false
			KEY_RIGHT:
				camera_x = min(level_width - PSX_WIDTH, camera_x + 50)
				auto_scroll = false
			KEY_UP:
				camera_y = max(0, camera_y - 50)
			KEY_DOWN:
				camera_y = min(level_height - PSX_HEIGHT, camera_y + 50)
			KEY_HOME:
				camera_x = 0
				camera_y = 0
			KEY_END:
				camera_x = level_width - PSX_WIDTH
			KEY_R:
				render_layers()
			KEY_SPACE:
				auto_scroll = not auto_scroll
			KEY_S:
				# Jump to spawn
				camera_x = clamp(spawn_x - PSX_WIDTH / 2.0, 0, level_width - PSX_WIDTH)
				camera_y = clamp(spawn_y - PSX_HEIGHT / 2.0, 0, level_height - PSX_HEIGHT)
			KEY_H:
				show_hud = not show_hud
			KEY_E:
				show_entities = not show_entities
				if entity_overlay:
					entity_overlay.queue_redraw()
			KEY_F:
				# Toggle fit-to-window mode
				fit_to_window = not fit_to_window
				update_window_scaling()
			KEY_TAB, KEY_L:
				# Toggle level selection menu
				toggle_level_menu()
			KEY_ESCAPE:
				if menu_visible:
					toggle_level_menu()
				else:
					get_tree().quit()

# ============================================================================
# Entity Overlay - Draws entity bounding boxes and sprites on top of layers
# ============================================================================

class EntityOverlay extends Node2D:
	var viewer  # Reference to parent ParallaxViewer
	
	func _draw() -> void:
		if not viewer or not viewer.show_entities:
			return
		
		var font = ThemeDB.fallback_font
		var font_size = 8
		
		for entity in viewer.entities:
			var x1 = entity.get("x1", 0) - viewer.camera_x
			var y1 = entity.get("y1", 0) - viewer.camera_y
			var x2 = entity.get("x2", 0) - viewer.camera_x
			var y2 = entity.get("y2", 0) - viewer.camera_y
			var entity_type = entity.get("type", 0)
			var entity_layer = entity.get("layer", 1)
			var variant = entity.get("variant", 0)
			
			# Skip entities outside viewport
			if x2 < 0 or x1 > viewer.PSX_WIDTH or y2 < 0 or y1 > viewer.PSX_HEIGHT:
				continue
			
			var w = x2 - x1
			var h = y2 - y1
			var cx = entity.get("x_center", 0) - viewer.camera_x
			var cy = entity.get("y_center", 0) - viewer.camera_y
			
			# Get colors from EntitySprites
			var box_color = EntitySpritesClass.get_layer_color(entity_layer)
			var entity_color = EntitySpritesClass.get_color(entity_type)
			
			# Try to draw sprite if available
			var sprite_drawn = false
			if viewer.show_entity_sprites and entity_type in viewer.entity_textures:
				var tex = viewer.entity_textures[entity_type] as Texture2D
				if tex != null:
					# Draw sprite centered on entity center
					var sprite_w = tex.get_width()
					var sprite_h = tex.get_height()
					var sprite_x = cx - sprite_w / 2.0
					var sprite_y = cy - sprite_h / 2.0
					draw_texture(tex, Vector2(sprite_x, sprite_y))
					sprite_drawn = true
			
			# Draw bounding box
			if not sprite_drawn or not viewer.show_entity_sprites:
				# No sprite - draw filled box with entity color
				draw_rect(Rect2(x1, y1, w, h), Color(entity_color, 0.3), true)
				draw_rect(Rect2(x1, y1, w, h), box_color, false, 1.0)
				# Draw center point
				draw_circle(Vector2(cx, cy), 2, Color(1, 0, 0, 0.8))
			else:
				# Sprite drawn - just thin outline
				draw_rect(Rect2(x1, y1, w, h), Color(box_color, 0.3), false, 1.0)
			
			# Draw type label
			var type_name = EntitySpritesClass.get_short_name(entity_type)
			var label = type_name
			if variant != 0:
				label += ":%d" % variant
			draw_string(font, Vector2(x1 + 1, y1 + font_size), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	func _process(_delta: float) -> void:
		queue_redraw()
