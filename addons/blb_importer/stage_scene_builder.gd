@tool
class_name StageSceneBuilder
## Builds Godot scenes from BLB stage data
##
## Creates a scene with:
## - Background ColorRect
## - TileSet from tile pixels and palettes
## - TileMapLayer for each layer
## - Animated entity sprites

const TILE_SIZE := 16
const TILES_PER_ROW := 32  # Atlas layout

const SpriteFramesBuilder = preload("res://addons/blb_importer/sprite_frames_builder.gd")
const EntitySprites = preload("res://addons/blb_importer/game_data/entity_sprites.gd")

var _blb = null  # BLBReader instance for sprite decoding


func build_scene(stage_data: Dictionary, blb = null) -> PackedScene:
	"""Build complete scene from stage data dictionary
	
	Args:
		stage_data: Dictionary from BLBReader.load_stage()
		blb: Optional BLBReader instance for sprite decoding
	"""
	_blb = blb
	
	var tile_header: Dictionary = stage_data.get("tile_header", {})
	var tile_pixels: PackedByteArray = stage_data.get("tile_pixels", PackedByteArray())
	var palette_indices: PackedByteArray = stage_data.get("palette_indices", PackedByteArray())
	var palettes: Array = stage_data.get("palettes", [])
	var layers: Array = stage_data.get("layers", [])
	var tilemaps: Array = stage_data.get("tilemaps", [])
	var entities: Array = stage_data.get("entities", [])
	var sprites: Array = stage_data.get("sprites", [])
	
	# Calculate total tiles
	var count_16x16: int = tile_header.get("count_16x16", 0)
	var count_8x8: int = tile_header.get("count_8x8", 0)
	var count_extra: int = tile_header.get("count_extra", 0)
	var total_tiles := count_16x16 + count_8x8 + count_extra
	
	if total_tiles == 0:
		push_error("[StageSceneBuilder] No tiles in stage")
		return null
	
	# Build the scene tree
	var root := Node2D.new()
	root.name = "%s_Stage%d" % [stage_data.get("level_id", "UNKN"), stage_data.get("stage_index", 0) + 1]
	
	# Add background
	_add_background(root, tile_header)
	
	# Build tileset with atlas texture
	var tileset := _build_tileset(tile_pixels, palette_indices, palettes, total_tiles, count_16x16)
	if not tileset:
		push_error("[StageSceneBuilder] Failed to build tileset")
		return null
	
	# Add tile layers
	_add_tile_layers(root, layers, tilemaps, tileset, count_16x16)
	
	# Add entities with sprites
	print("[StageSceneBuilder] Entities: %d, Sprites: %d, BLB: %s" % [entities.size(), sprites.size(), _blb != null])
	_add_entities(root, entities, sprites)
	
	# Add spawn point marker
	_add_spawn_point(root, tile_header)
	
	# Store metadata on root
	root.set_meta("level_name", stage_data.get("level_name", "Unknown"))
	root.set_meta("level_id", stage_data.get("level_id", "UNKN"))
	root.set_meta("level_index", stage_data.get("level_index", 0))
	root.set_meta("stage_index", stage_data.get("stage_index", 0))
	
	# Pack and return scene
	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("[StageSceneBuilder] Failed to pack scene")
		return null
	
	return packed


func _add_background(root: Node2D, tile_header: Dictionary) -> void:
	"""Add background ColorRect"""
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


func _build_tileset(tile_pixels: PackedByteArray, palette_indices: PackedByteArray,
                    palettes: Array, total_tiles: int, count_16x16: int) -> TileSet:
	"""Build TileSet with composite atlas texture"""
	
	if tile_pixels.is_empty() or palettes.is_empty():
		return null
	
	# Build atlas texture
	var atlas_image := _build_atlas_image(tile_pixels, palette_indices, palettes, 
	                                       total_tiles, count_16x16)
	if not atlas_image:
		return null
	
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	
	# Create TileSet
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create atlas source
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	
	# Create tiles in atlas
	for tile_idx in range(total_tiles):
		var atlas_x := tile_idx % TILES_PER_ROW
		var atlas_y := tile_idx / TILES_PER_ROW
		atlas_source.create_tile(Vector2i(atlas_x, atlas_y))
	
	tileset.add_source(atlas_source, 0)
	return tileset


func _build_atlas_image(tile_pixels: PackedByteArray, palette_indices: PackedByteArray,
                        palettes: Array, total_tiles: int, count_16x16: int) -> Image:
	"""Build composite atlas image from indexed tiles"""
	
	var atlas_rows := ceili(float(total_tiles) / TILES_PER_ROW)
	var atlas_width := TILES_PER_ROW * TILE_SIZE
	var atlas_height := atlas_rows * TILE_SIZE
	
	var image := Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent
	
	# Process each tile
	var pixels_per_16x16_tile := TILE_SIZE * TILE_SIZE  # 256
	var pixels_per_8x8_tile := 8 * 8  # 64
	
	var pixel_offset := 0
	
	for tile_idx in range(total_tiles):
		# Determine tile size
		var is_8x8 := tile_idx >= count_16x16
		var tile_width := 8 if is_8x8 else TILE_SIZE
		var tile_height := 8 if is_8x8 else TILE_SIZE
		var pixels_in_tile := tile_width * tile_height
		
		# Get palette for this tile
		var pal_idx := 0
		if tile_idx < palette_indices.size():
			pal_idx = palette_indices[tile_idx]
		
		var palette: PackedColorArray
		if pal_idx < palettes.size():
			palette = palettes[pal_idx]
		else:
			palette = PackedColorArray()
		
		# Atlas position
		var atlas_x := (tile_idx % TILES_PER_ROW) * TILE_SIZE
		var atlas_y := (tile_idx / TILES_PER_ROW) * TILE_SIZE
		
		# Convert indexed pixels to RGBA
		for py in range(tile_height):
			for px in range(tile_width):
				var src_offset := pixel_offset + py * tile_width + px
				if src_offset >= tile_pixels.size():
					continue
				
				var color_idx := tile_pixels[src_offset]
				var color := Color(0, 0, 0, 0)  # Default transparent
				
				if color_idx < palette.size():
					color = palette[color_idx]
				elif color_idx > 0:
					# Fallback: grayscale
					color = Color8(color_idx, color_idx, color_idx, 255)
				
				# For 8x8 tiles, scale 2x to fill 16x16 cell (PSX-authentic behavior)
				# Verified via Ghidra: RenderTilemapSprites16x16 (0x8001713c) always uses
				# SPRT_16 and 16-pixel grid spacing regardless of tile size
				if is_8x8:
					# Scale 2x: each 8x8 pixel becomes a 2x2 block
					var dest_x := atlas_x + px * 2
					var dest_y := atlas_y + py * 2
					if dest_x + 1 < atlas_width and dest_y + 1 < atlas_height:
						image.set_pixel(dest_x, dest_y, color)
						image.set_pixel(dest_x + 1, dest_y, color)
						image.set_pixel(dest_x, dest_y + 1, color)
						image.set_pixel(dest_x + 1, dest_y + 1, color)
				else:
					var dest_x := atlas_x + px
					var dest_y := atlas_y + py
					if dest_x < atlas_width and dest_y < atlas_height:
						image.set_pixel(dest_x, dest_y, color)
		
		pixel_offset += pixels_in_tile
	
	return image


func _add_tile_layers(root: Node2D, layers: Array, tilemaps: Array, 
                      tileset: TileSet, count_16x16: int) -> void:
	"""Add TileMapLayer nodes for each layer"""
	
	var layers_container := Node2D.new()
	layers_container.name = "TileLayers"
	root.add_child(layers_container)
	layers_container.owner = root
	
	for i in range(layers.size()):
		var layer: Dictionary = layers[i]
		
		# Skip layers marked as skip
		if layer.get("skip", false):
			continue
		
		var layer_width: int = layer.get("width", 0)
		var layer_height: int = layer.get("height", 0)
		
		if layer_width == 0 or layer_height == 0:
			continue
		
		# Get tilemap data
		if i >= tilemaps.size():
			continue
		var tilemap: PackedInt32Array = tilemaps[i]
		
		# Create TileMapLayer
		var tile_layer := TileMapLayer.new()
		tile_layer.name = "Layer_%d" % i
		tile_layer.tile_set = tileset
		tile_layer.z_index = i
		
		# Position offset
		tile_layer.position = Vector2(
			layer.get("x_offset", 0) * TILE_SIZE,
			layer.get("y_offset", 0) * TILE_SIZE
		)
		
		# Set tiles
		var tile_idx := 0
		for y in range(layer_height):
			for x in range(layer_width):
				if tile_idx >= tilemap.size():
					break
				
				var tile_id: int = tilemap[tile_idx]
				tile_idx += 1
				
				if tile_id == 0:
					continue  # Transparent/empty
				
				# Convert 1-based tile ID to atlas coords (0-based)
				var atlas_idx := tile_id - 1
				var atlas_x := atlas_idx % TILES_PER_ROW
				var atlas_y := atlas_idx / TILES_PER_ROW
				
				tile_layer.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, atlas_y))
		
		# Handle parallax
		# scroll_x/y are 16.16 fixed-point: 65536 = 1.0, 0 = static (fixed to screen)
		var scroll_x_raw: int = layer.get("scroll_x", 65536)
		var scroll_y_raw: int = layer.get("scroll_y", 65536)
		var scroll_x: float = float(scroll_x_raw) / 65536.0
		var scroll_y: float = float(scroll_y_raw) / 65536.0
		
		# Store scroll values on layer for runtime access
		tile_layer.set_meta("scroll_x", scroll_x_raw)
		tile_layer.set_meta("scroll_y", scroll_y_raw)
		tile_layer.set_meta("scroll_x_float", scroll_x)
		tile_layer.set_meta("scroll_y_float", scroll_y)
		
		# Always add directly to container - let runtime handle parallax
		layers_container.add_child(tile_layer)
		tile_layer.owner = root


func _add_entities(root: Node2D, entities: Array, sprites: Array) -> void:
	"""Add entity nodes using BLBEntityBase scene structure
	
	Following Godot best practices (scene organization):
	- Each entity is a self-contained node with script extending BLBEntityBase
	- Sprite is a child of the entity node
	- Loose coupling via signals (collected, player_damaged, etc.)
	"""
	
	var entities_container := Node2D.new()
	entities_container.name = "Entities"
	entities_container.z_index = 100
	root.add_child(entities_container)
	entities_container.owner = root
	
	# Build a sprite lookup map by sprite_id for entity→sprite matching
	var sprite_by_id: Dictionary = {}
	for sprite in sprites:
		var sprite_id = sprite.get("id", 0)
		if sprite_id != 0:
			sprite_by_id[sprite_id] = sprite
	
	print("[StageSceneBuilder] Sprite ID lookup: %d sprites indexed" % sprite_by_id.size())
	
	# Preload registry for entity creation
	var EntityRegistry = preload("res://addons/blb_importer/entity_callbacks/entity_callback_registry.gd")
	
	for i in range(entities.size()):
		var entity_def: Dictionary = entities[i]
		var entity_type: int = entity_def.get("entity_type", 0)
		
		# Create entity node using registry (gets proper script attached)
		var entity_node: Node2D = EntityRegistry.create_entity_node(entity_type)
		entity_node.name = "Entity_%d_T%d" % [i, entity_type]
		entity_node.position = Vector2(
			entity_def.get("x_center", 0),
			entity_def.get("y_center", 0)
		)
		
		# Set exported properties (BLBEntityBase exports)
		entity_node.entity_type = entity_type
		entity_node.variant = entity_def.get("variant", 0)
		entity_node.layer = entity_def.get("layer", 0)
		entity_node.bounds = Rect2(
			entity_def.get("x1", 0),
			entity_def.get("y1", 0),
			entity_def.get("x2", 0) - entity_def.get("x1", 0),
			entity_def.get("y2", 0) - entity_def.get("y1", 0)
		)
		entity_node.entity_index = i
		
		# Look up sprite using EntitySprites mapping
		var target_sprite_id = EntitySprites.get_sprite_id(entity_type)
		var sprite: Dictionary = {}
		
		if target_sprite_id != null and target_sprite_id in sprite_by_id:
			sprite = sprite_by_id[target_sprite_id]
		
		if not sprite.is_empty() and _blb != null:
			# Create AnimatedSprite2D with all animations
			var anim_sprite := AnimatedSprite2D.new()
			anim_sprite.name = "Sprite"
			anim_sprite.sprite_frames = SpriteFramesBuilder.build_sprite_frames(_blb, sprite)
			anim_sprite.centered = true
			
			# Auto-play first animation
			var anims := anim_sprite.sprite_frames.get_animation_names()
			if anims.size() > 0:
				anim_sprite.animation = anims[0]
				anim_sprite.play()
			
			entity_node.add_child(anim_sprite)
			anim_sprite.owner = root
		else:
			# Fallback: create a simple colored rect as placeholder
			var placeholder := ColorRect.new()
			placeholder.name = "Placeholder"
			placeholder.color = EntitySprites.get_color(entity_type)
			placeholder.size = Vector2(
				max(8, entity_def.get("x2", 16) - entity_def.get("x1", 0)),
				max(8, entity_def.get("y2", 16) - entity_def.get("y1", 0))
			)
			placeholder.position = -placeholder.size / 2  # Center it
			entity_node.add_child(placeholder)
			placeholder.owner = root
			
			# Add a label showing entity type
			var label := Label.new()
			label.text = EntitySprites.get_short_name(entity_type)
			label.add_theme_font_size_override("font_size", 8)
			label.position = Vector2(-8, -16)
			entity_node.add_child(label)
			label.owner = root
		
		entities_container.add_child(entity_node)
		entity_node.owner = root


func _add_spawn_point(root: Node2D, tile_header: Dictionary) -> void:
	"""Add player spawn point marker"""
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(
		tile_header.get("spawn_x", 0) * TILE_SIZE + TILE_SIZE / 2,
		tile_header.get("spawn_y", 0) * TILE_SIZE + TILE_SIZE - 1
	)
	spawn.gizmo_extents = 20.0
	root.add_child(spawn)
	spawn.owner = root
