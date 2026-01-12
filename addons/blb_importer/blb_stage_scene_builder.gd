@tool
extends RefCounted
class_name BLBStageSceneBuilder
## Builds Godot scenes from BLB stage data using proper BLB node types
##
## Creates a hierarchical scene that mirrors the BLB file structure:
##
## BLBStageRoot (level/stage info)
## ├── Background (ColorRect)
## ├── TilesetContainer (Asset 300, 301, 302, 400)
## │   └── [TileSet resource]
## ├── PaletteContainer (Asset 400)
## │   └── Palette_0..N (BLBPalette)
## ├── LayerContainer (Asset 200, 201)
## │   └── Layer_0..N (BLBLayer as TileMapLayer)
## ├── EntityContainer (Asset 501)
## │   └── Entity_0..N (BLBEntity)
## ├── SpriteContainer (Asset 600)
## │   └── Sprite_0..N (BLBSprite as AnimatedSprite2D)
## ├── TileAttributes (Asset 500)
## └── SpawnPoint (Marker2D)

const TILE_SIZE := 16
const TILES_PER_ROW := 32  # Atlas layout

# Preload node scripts
const BLBStageRoot = preload("res://addons/blb_importer/nodes/blb_stage_root.gd")
const BLBTilesetContainer = preload("res://addons/blb_importer/nodes/blb_tileset_container.gd")
const BLBLayerContainer = preload("res://addons/blb_importer/nodes/blb_layer_container.gd")
const BLBLayer = preload("res://addons/blb_importer/nodes/blb_layer.gd")
const BLBEntityContainer = preload("res://addons/blb_importer/nodes/blb_entity_container.gd")
const BLBEntity = preload("res://addons/blb_importer/nodes/blb_entity.gd")
const BLBSpriteContainer = preload("res://addons/blb_importer/nodes/blb_sprite_container.gd")
const BLBSprite = preload("res://addons/blb_importer/nodes/blb_sprite.gd")
const BLBPaletteContainer = preload("res://addons/blb_importer/nodes/blb_palette_container.gd")
const BLBPalette = preload("res://addons/blb_importer/nodes/blb_palette.gd")
const BLBTileAttributes = preload("res://addons/blb_importer/nodes/blb_tile_attributes.gd")

var _blb = null  # BLBReader instance


func build_scene(stage_data: Dictionary, blb = null) -> PackedScene:
	"""Build complete scene from stage data dictionary
	
	Args:
		stage_data: Dictionary from BLBReader.load_stage()
		blb: BLBReader instance for sprite decoding
	"""
	_blb = blb
	
	var tile_header: Dictionary = stage_data.get("tile_header", {})
	var tile_pixels: PackedByteArray = stage_data.get("tile_pixels", PackedByteArray())
	var palette_indices: PackedByteArray = stage_data.get("palette_indices", PackedByteArray())
	var tile_flags: PackedByteArray = stage_data.get("tile_flags", PackedByteArray())
	var palettes: Array = stage_data.get("palettes", [])
	var layers: Array = stage_data.get("layers", [])
	var tilemaps: Array = stage_data.get("tilemaps", [])
	var entities: Array = stage_data.get("entities", [])
	var sprites: Array = stage_data.get("sprites", [])
	var tile_attributes: PackedByteArray = stage_data.get("tile_attributes", PackedByteArray())
	
	# Calculate total tiles
	var count_16x16: int = tile_header.get("count_16x16", 0)
	var count_8x8: int = tile_header.get("count_8x8", 0)
	var count_extra: int = tile_header.get("count_extra", 0)
	var total_tiles := count_16x16 + count_8x8 + count_extra
	
	if total_tiles == 0:
		push_error("[BLBStageSceneBuilder] No tiles in stage")
		return null
	
	# Create root node
	var root := Node2D.new()
	root.set_script(BLBStageRoot)
	root.name = "%s_Stage%d" % [stage_data.get("level_id", "UNKN"), stage_data.get("stage_index", 0) + 1]
	
	# Set root properties
	root.level_id = stage_data.get("level_id", "")
	root.level_name = stage_data.get("level_name", "")
	root.level_index = stage_data.get("level_index", 0)
	root.stage_index = stage_data.get("stage_index", 0)
	root.bg_color = Color8(
		tile_header.get("bg_r", 0),
		tile_header.get("bg_g", 0),
		tile_header.get("bg_b", 0)
	)
	root.level_width = tile_header.get("level_width", 0)
	root.level_height = tile_header.get("level_height", 0)
	root.spawn_x = tile_header.get("spawn_x", 0)
	root.spawn_y = tile_header.get("spawn_y", 0)
	root.count_16x16 = count_16x16
	root.count_8x8 = count_8x8
	root.count_extra = count_extra
	root.entity_count = entities.size()
	
	# Add background
	_add_background(root, tile_header)
	
	# Build and add tileset container
	var tileset_result := _build_tileset_container(tile_pixels, palette_indices, tile_flags, palettes, total_tiles, count_16x16)
	if tileset_result.container:
		root.add_child(tileset_result.container)
		tileset_result.container.owner = root
	
	# Add palette container
	_add_palette_container(root, palettes)
	
	# Add layer container with tilemaps
	if tileset_result.tileset:
		_add_layer_container(root, layers, tilemaps, tileset_result.tileset, count_16x16)
	
	# Add entity container
	_add_entity_container(root, entities, sprites)
	
	# Add sprite container (separate from entities for browsing)
	_add_sprite_container(root, sprites)
	
	# Add tile attributes
	_add_tile_attributes(root, tile_attributes)
	
	# Add spawn point marker
	_add_spawn_point(root, tile_header)
	
	# Pack and return scene
	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("[BLBStageSceneBuilder] Failed to pack scene")
		return null
	
	print("[BLBStageSceneBuilder] Built scene: %s with %d layers, %d entities, %d sprites" % [
		root.name, layers.size(), entities.size(), sprites.size()
	])
	
	return packed


func _add_background(root: Node2D, tile_header: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color8(
		tile_header.get("bg_r", 0),
		tile_header.get("bg_g", 0),
		tile_header.get("bg_b", 0)
	)
	bg.size = Vector2(
		tile_header.get("level_width", 320) * TILE_SIZE,
		tile_header.get("level_height", 240) * TILE_SIZE
	)
	bg.z_index = -100
	root.add_child(bg)
	bg.owner = root


func _build_tileset_container(tile_pixels: PackedByteArray, palette_indices: PackedByteArray,
		tile_flags: PackedByteArray, palettes: Array, total_tiles: int, count_16x16: int) -> Dictionary:
	"""Build tileset container with atlas texture"""
	var container := Node2D.new()
	container.set_script(BLBTilesetContainer)
	container.name = "TilesetContainer"
	
	container.tile_pixel_count = total_tiles
	container.tile_pixels_size = tile_pixels.size()
	container.palette_index_count = palette_indices.size()
	container.tile_flag_count = tile_flags.size()
	container.palette_count = palettes.size()
	
	# Build tile atlas texture
	var atlas_image := _build_tile_atlas(tile_pixels, palette_indices, palettes, total_tiles)
	if not atlas_image:
		return {"container": container, "tileset": null}
	
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	container.tile_atlas = atlas_texture
	
	# Build TileSet
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	var atlas_cols := TILES_PER_ROW
	var atlas_rows := (total_tiles + atlas_cols - 1) / atlas_cols
	
	for tile_idx in range(total_tiles):
		var atlas_x := tile_idx % atlas_cols
		var atlas_y := tile_idx / atlas_cols
		source.create_tile(Vector2i(atlas_x, atlas_y))
	
	tileset.add_source(source, 0)
	container.tileset = tileset
	
	return {"container": container, "tileset": tileset}


func _build_tile_atlas(tile_pixels: PackedByteArray, palette_indices: PackedByteArray,
		palettes: Array, total_tiles: int) -> Image:
	"""Build atlas image from tile pixels"""
	if palettes.is_empty():
		return null
	
	var atlas_cols := TILES_PER_ROW
	var atlas_rows := (total_tiles + atlas_cols - 1) / atlas_cols
	var atlas_width := atlas_cols * TILE_SIZE
	var atlas_height := atlas_rows * TILE_SIZE
	
	var atlas := Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	
	var bytes_per_tile := TILE_SIZE * TILE_SIZE
	
	for tile_idx in range(total_tiles):
		var tile_offset := tile_idx * bytes_per_tile
		if tile_offset + bytes_per_tile > tile_pixels.size():
			continue
		
		# Get palette for this tile
		var pal_idx := 0
		if tile_idx < palette_indices.size():
			pal_idx = palette_indices[tile_idx]
		if pal_idx >= palettes.size():
			pal_idx = 0
		var palette: PackedColorArray = palettes[pal_idx] if palettes.size() > 0 else PackedColorArray()
		
		# Atlas position
		var atlas_x := (tile_idx % atlas_cols) * TILE_SIZE
		var atlas_y := (tile_idx / atlas_cols) * TILE_SIZE
		
		# Copy pixels
		for py in range(TILE_SIZE):
			for px in range(TILE_SIZE):
				var pixel_offset := tile_offset + py * TILE_SIZE + px
				if pixel_offset >= tile_pixels.size():
					continue
				
				var color_idx := tile_pixels[pixel_offset]
				var color := Color.MAGENTA
				if color_idx < palette.size():
					color = palette[color_idx]
					# Index 0 is transparent
					if color_idx == 0:
						color.a = 0.0
				
				atlas.set_pixel(atlas_x + px, atlas_y + py, color)
	
	return atlas


func _add_palette_container(root: Node2D, palettes: Array) -> void:
	var container := Node2D.new()
	container.set_script(BLBPaletteContainer)
	container.name = "PaletteContainer"
	container.palette_count = palettes.size()
	container.visible = false  # Hidden by default, just for inspection
	
	for i in range(palettes.size()):
		var pal_node := Control.new()
		pal_node.set_script(BLBPalette)
		pal_node.name = "Palette_%d" % i
		pal_node.palette_index = i
		pal_node.colors = palettes[i]
		pal_node.color_count = palettes[i].size()
		
		container.add_child(pal_node)
		pal_node.owner = root
	
	root.add_child(container)
	container.owner = root


func _add_layer_container(root: Node2D, layers: Array, tilemaps: Array, tileset: TileSet, count_16x16: int) -> void:
	var container := Node2D.new()
	container.set_script(BLBLayerContainer)
	container.name = "LayerContainer"
	container.layer_count = layers.size()
	
	for layer_idx in range(layers.size()):
		var layer_data: Dictionary = layers[layer_idx]
		var tilemap_idx: int = layer_data.get("tilemap_index", layer_idx)
		
		if tilemap_idx >= tilemaps.size():
			continue
		
		var layer := TileMapLayer.new()
		layer.set_script(BLBLayer)
		layer.name = "Layer_%d" % layer_idx
		layer.tile_set = tileset
		
		# Set layer properties
		layer.layer_index = layer_idx
		layer.map_width = layer_data.get("width", 0)
		layer.map_height = layer_data.get("height", 0)
		layer.x_offset = layer_data.get("x_offset", 0)
		layer.y_offset = layer_data.get("y_offset", 0)
		layer.scroll_x = layer_data.get("scroll_x", 0x10000)
		layer.scroll_y = layer_data.get("scroll_y", 0x10000)
		layer.layer_flags = layer_data.get("flags", 0)
		layer.tilemap_index = tilemap_idx
		
		# Position and z-index
		layer.position = Vector2(layer.x_offset, layer.y_offset)
		layer.z_index = layer_idx - layers.size()
		
		# Fill tilemap
		var tilemap_data: PackedByteArray = tilemaps[tilemap_idx]
		var tile_count := 0
		for y in range(layer.map_height):
			for x in range(layer.map_width):
				var idx: int = (y * layer.map_width + x) * 2
				if idx + 2 > tilemap_data.size():
					continue
				
				var tile_value: int = tilemap_data[idx] | (tilemap_data[idx + 1] << 8)
				var tile_index: int = tile_value & 0x7FF
				
				if tile_index > 0:  # 0 = empty
					var atlas_x: int = (tile_index - 1) % TILES_PER_ROW
					var atlas_y: int = (tile_index - 1) / TILES_PER_ROW
					layer.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, atlas_y))
					tile_count += 1
		
		layer.tile_count = tile_count
		
		container.add_child(layer)
		layer.owner = root
	
	root.add_child(container)
	container.owner = root


func _add_entity_container(root: Node2D, entities: Array, sprites: Array) -> void:
	var container := Node2D.new()
	container.set_script(BLBEntityContainer)
	container.name = "EntityContainer"
	container.entity_count = entities.size()
	
	for i in range(entities.size()):
		var entity_data: Dictionary = entities[i]
		
		var entity := Node2D.new()
		entity.set_script(BLBEntity)
		entity.name = "Entity_%d_T%d" % [i, entity_data.get("entity_type", 0)]
		
		# Set entity properties
		entity.entity_index = i
		entity.x1 = entity_data.get("x1", 0)
		entity.y1 = entity_data.get("y1", 0)
		entity.x2 = entity_data.get("x2", 0)
		entity.y2 = entity_data.get("y2", 0)
		entity.x_center = entity_data.get("x_center", 0)
		entity.y_center = entity_data.get("y_center", 0)
		entity.entity_type = entity_data.get("entity_type", 0)
		entity.variant = entity_data.get("variant", 0)
		entity.layer = entity_data.get("layer", 0)
		
		# Position at center
		entity.position = Vector2(entity.x_center, entity.y_center)
		
		# Add visual placeholder for now
		var placeholder := ColorRect.new()
		placeholder.name = "Bounds"
		placeholder.color = Color(1, 0.5, 0, 0.5)  # Orange semi-transparent
		placeholder.size = Vector2(entity.x2 - entity.x1, entity.y2 - entity.y1)
		placeholder.position = -placeholder.size / 2
		entity.add_child(placeholder)
		placeholder.owner = root
		
		# Add type label
		var label := Label.new()
		label.name = "TypeLabel"
		label.text = "T%d" % entity.entity_type
		label.add_theme_font_size_override("font_size", 8)
		label.position = Vector2(-12, -20)
		entity.add_child(label)
		label.owner = root
		
		container.add_child(entity)
		entity.owner = root
	
	root.add_child(container)
	container.owner = root


func _add_sprite_container(root: Node2D, sprites: Array) -> void:
	var container := Node2D.new()
	container.set_script(BLBSpriteContainer)
	container.name = "SpriteContainer"
	container.sprite_count = sprites.size()
	container.visible = false  # Hidden by default, just for browsing
	
	for i in range(sprites.size()):
		var sprite_data: Dictionary = sprites[i]
		
		var sprite := AnimatedSprite2D.new()
		sprite.set_script(BLBSprite)
		sprite.name = "Sprite_%d" % i
		
		# Set sprite properties from parsed data
		sprite.sprite_id = sprite_data.get("id", 0)
		sprite.sprite_id_hex = sprite_data.get("id_hex", "")
		sprite.anim_count = sprite_data.get("anim_count", 0)
		sprite.rle_data_offset = sprite_data.get("rle_offset", 0)
		
		# Get animation names
		var animations: Array = sprite_data.get("animations", [])
		var anim_names := PackedStringArray()
		var total_frames := 0
		for anim in animations:
			var anim_id: int = anim.get("id", 0)
			anim_names.append("anim_%d" % anim_id)
			total_frames += anim.get("frame_count", 0)
		sprite.animation_names = anim_names
		sprite.total_frame_count = total_frames
		
		# Build SpriteFrames if we have the BLB reader
		if _blb:
			sprite.sprite_frames = _build_sprite_frames(sprite_data)
		
		# Position sprites in a grid for preview
		sprite.position = Vector2((i % 10) * 64, (i / 10) * 64)
		
		container.add_child(sprite)
		sprite.owner = root
	
	root.add_child(container)
	container.owner = root


func _build_sprite_frames(sprite_data: Dictionary) -> SpriteFrames:
	"""Build SpriteFrames resource from sprite data"""
	if not _blb:
		return null
	
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	
	var animations: Array = sprite_data.get("animations", [])
	for anim_idx in range(animations.size()):
		var anim: Dictionary = animations[anim_idx]
		var anim_name := "anim_%d" % anim.get("id", anim_idx)
		
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 10.0)  # Default 10 FPS
		
		var frame_list: Array = anim.get("frames", [])
		for frame_idx in range(frame_list.size()):
			var image: Image = _blb.decode_sprite_frame(sprite_data, anim_idx, frame_idx)
			if image:
				var texture: ImageTexture = ImageTexture.create_from_image(image)
				frames.add_frame(anim_name, texture)
	
	return frames


func _add_tile_attributes(root: Node2D, tile_attributes: PackedByteArray) -> void:
	var attr_node := Node2D.new()
	attr_node.set_script(BLBTileAttributes)
	attr_node.name = "TileAttributes"
	attr_node.attribute_count = tile_attributes.size()
	attr_node.data_size = tile_attributes.size()
	attr_node.attributes = tile_attributes
	attr_node.visible = false  # Hidden, just for inspection
	
	root.add_child(attr_node)
	attr_node.owner = root


func _add_spawn_point(root: Node2D, tile_header: Dictionary) -> void:
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(
		tile_header.get("spawn_x", 0) * TILE_SIZE + TILE_SIZE / 2,
		tile_header.get("spawn_y", 0) * TILE_SIZE + TILE_SIZE - 1
	)
	spawn.gizmo_extents = 20.0
	root.add_child(spawn)
	spawn.owner = root
