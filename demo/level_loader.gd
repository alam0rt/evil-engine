@tool
extends Node2D
## Level Loader - Loads exported BLB assets and renders using Godot TileMapLayer
##
## Uses exported JSON/PNG assets from export_assets tool.
## Each layer becomes a TileMapLayer with proper parallax.

const TILE_SIZE := 16

## Path to exported assets directory
@export_dir var assets_path: String = "":
	set(value):
		assets_path = value
		if Engine.is_editor_hint() and is_inside_tree():
			_load_level()

## Show entity debug overlay
@export var show_entities: bool = true:
	set(value):
		show_entities = value
		if _entity_overlay:
			_entity_overlay.visible = value

var _level_info: Dictionary = {}
var _layers_data: Array = []
var _entities_data: Array = []
var _tile_atlas: Texture2D = null
var _tile_set: TileSet = null
var _entity_overlay: Node2D = null
var _background: ColorRect = null

func _ready() -> void:
	if assets_path != "":
		_load_level()

func _load_level() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	if assets_path == "":
		return
	
	# Load level info
	var info_path := assets_path.path_join("level_info.json")
	if not FileAccess.file_exists(info_path):
		push_error("Level info not found: " + info_path)
		return
	
	var info_file := FileAccess.open(info_path, FileAccess.READ)
	_level_info = JSON.parse_string(info_file.get_as_text())
	info_file.close()
	
	# Load layers data
	var layers_path := assets_path.path_join("layers.json")
	if FileAccess.file_exists(layers_path):
		var layers_file := FileAccess.open(layers_path, FileAccess.READ)
		_layers_data = JSON.parse_string(layers_file.get_as_text())
		layers_file.close()
	
	# Load entities data
	var entities_path := assets_path.path_join("entities.json")
	if FileAccess.file_exists(entities_path):
		var entities_file := FileAccess.open(entities_path, FileAccess.READ)
		_entities_data = JSON.parse_string(entities_file.get_as_text())
		entities_file.close()
	
	# Load tile atlas
	var tiles_path := assets_path.path_join("tiles.png")
	if FileAccess.file_exists(tiles_path):
		var image := Image.load_from_file(tiles_path)
		_tile_atlas = ImageTexture.create_from_image(image)
	
	if _tile_atlas == null:
		push_error("Tile atlas not found: " + tiles_path)
		return
	
	# Create TileSet
	_create_tileset()
	
	# Create background
	_create_background()
	
	# Create layers
	_create_layers()
	
	# Create entity overlay
	_create_entity_overlay()
	
	print("Loaded level: ", _level_info.get("level_name", "Unknown"))
	print("  Layers: ", _layers_data.size())
	print("  Entities: ", _entities_data.size())

func _create_tileset() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create atlas source from tile image
	var source := TileSetAtlasSource.new()
	source.texture = _tile_atlas
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Calculate grid dimensions
	var tiles_per_row: int = _level_info.get("tiles_per_row", 37)
	var tile_count: int = _level_info.get("tile_count", 0)
	var rows: int = ceili(float(tile_count) / tiles_per_row)
	
	# Create tiles in the atlas
	for tile_idx in range(tile_count):
		var atlas_x: int = tile_idx % tiles_per_row
		var atlas_y: int = tile_idx / tiles_per_row
		var atlas_coords := Vector2i(atlas_x, atlas_y)
		
		# Create tile at this position
		source.create_tile(atlas_coords)
	
	# Add source to tileset (ID 0)
	_tile_set.add_source(source, 0)

func _create_background() -> void:
	var bg_color: Array = _level_info.get("background_color", [0, 0, 0])
	
	_background = ColorRect.new()
	_background.color = Color8(bg_color[0], bg_color[1], bg_color[2])
	_background.size = Vector2(
		_level_info.get("level_width_px", 320),
		_level_info.get("level_height_px", 240)
	)
	_background.z_index = -100
	add_child(_background)

func _create_layers() -> void:
	var tiles_per_row: int = _level_info.get("tiles_per_row", 37)
	
	for layer_data in _layers_data:
		if layer_data.get("skip", false):
			continue
		
		var layer_idx: int = layer_data.get("index", 0)
		var layer_width: int = layer_data.get("width", 0)
		var layer_height: int = layer_data.get("height", 0)
		var scroll_x: float = layer_data.get("scroll_x", 1.0)
		var scroll_y: float = layer_data.get("scroll_y", 1.0)
		var tilemap: Array = layer_data.get("tilemap", [])
		
		if layer_width == 0 or layer_height == 0:
			continue
		
		# Create TileMapLayer for this layer
		var tile_layer := TileMapLayer.new()
		tile_layer.name = "Layer_%d" % layer_idx
		tile_layer.tile_set = _tile_set
		tile_layer.z_index = layer_idx
		
		# Set layer position offset
		tile_layer.position = Vector2(
			layer_data.get("x_offset", 0) * TILE_SIZE,
			layer_data.get("y_offset", 0) * TILE_SIZE
		)
		
		# Populate tilemap
		var tile_idx := 0
		for y in range(layer_height):
			for x in range(layer_width):
				if tile_idx >= tilemap.size():
					break
				
				var tile_id: int = tilemap[tile_idx]
				tile_idx += 1
				
				if tile_id == 0:
					continue  # Empty/transparent
				
				# Convert tile_id (1-based) to atlas coords (0-based)
				var atlas_idx := tile_id - 1
				var atlas_x: int = atlas_idx % tiles_per_row
				var atlas_y: int = atlas_idx / tiles_per_row
				
				# Set tile in TileMapLayer
				tile_layer.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, atlas_y))
		
		# Handle different scroll modes:
		# scroll=0: Static background, locked to viewport (CanvasLayer)
		# scroll<1: Parallax backgrounds (Parallax2D)
		# scroll=1: Main layer, no parallax needed
		if scroll_x == 0.0 and scroll_y == 0.0:
			# Static background - use CanvasLayer to lock it to the viewport
			var canvas := CanvasLayer.new()
			canvas.name = "StaticBG_Layer_%d" % layer_idx
			canvas.layer = layer_idx - 100  # Behind main layers
			canvas.follow_viewport_enabled = true
			canvas.add_child(tile_layer)
			tile_layer.position = Vector2(
				layer_data.get("x_offset", 0) * TILE_SIZE,
				layer_data.get("y_offset", 0) * TILE_SIZE
			)
			add_child(canvas)
		elif scroll_x < 1.0 or scroll_y < 1.0:
			# Parallax layer - moves slower than camera
			var parallax := Parallax2D.new()
			parallax.name = "Parallax_Layer_%d" % layer_idx
			parallax.scroll_scale = Vector2(scroll_x, scroll_y)
			parallax.z_index = layer_idx
			parallax.add_child(tile_layer)
			tile_layer.position = Vector2.ZERO  # Reset, parallax handles it
			add_child(parallax)
		else:
			add_child(tile_layer)
		
		print("  Layer %d: %dx%d tiles, scroll=(%.2f, %.2f)" % [
			layer_idx, layer_width, layer_height, scroll_x, scroll_y
		])

func _create_entity_overlay() -> void:
	_entity_overlay = Node2D.new()
	_entity_overlay.name = "EntityOverlay"
	_entity_overlay.z_index = 1000
	_entity_overlay.visible = show_entities
	add_child(_entity_overlay)
	
	# Create visual for each entity
	for entity in _entities_data:
		var entity_node := _create_entity_visual(entity)
		_entity_overlay.add_child(entity_node)

func _create_entity_visual(entity: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.name = "Entity_%d" % entity.get("id", 0)
	
	var x1: int = entity.get("x1", 0)
	var y1: int = entity.get("y1", 0)
	var x2: int = entity.get("x2", 0)
	var y2: int = entity.get("y2", 0)
	var entity_type: int = entity.get("type", 0)
	
	# Position at center
	node.position = Vector2(
		entity.get("x_center", (x1 + x2) / 2),
		entity.get("y_center", (y1 + y2) / 2)
	)
	
	# Add bounding box (ColorRect)
	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.3)  # Semi-transparent red
	rect.size = Vector2(x2 - x1, y2 - y1)
	rect.position = Vector2(x1, y1) - node.position
	node.add_child(rect)
	
	# Add type label
	var label := Label.new()
	label.text = str(entity_type)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-8, -12)
	node.add_child(label)
	
	return node

## Get spawn position in pixels
func get_spawn_position() -> Vector2:
	return Vector2(
		_level_info.get("spawn_x", 0),
		_level_info.get("spawn_y", 0)
	)

## Get level dimensions in pixels
func get_level_size() -> Vector2:
	return Vector2(
		_level_info.get("level_width_px", 320),
		_level_info.get("level_height_px", 240)
	)
